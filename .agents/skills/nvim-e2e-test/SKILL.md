---
name: nvim-e2e-test
description: End-to-end testing of UI and keymap behavior in this Neovim config by driving a real nvim inside tmux — sending literal key sequences (including races/typeahead), capturing the pane, and inspecting live Lua state, logs and caches. Use when a bug only shows up in the real UI or with keystrokes (Lazy/floats/dashboard), when headless reproduction fails, or to validate a UI/keymap fix before and after.
compatibility: opencode
---

# E2E testing the Neovim UI with tmux

Headless smoke tests (`nvim --headless "+lua vim.cmd('qa')"`) only catch startup
errors. They cannot exercise UI code, because several UIs bail out when there is
no UI: `lazy.view.show` starts with `if Config.headless() then return end`, so
`:Lazy` is a no-op headless. Anything that needs a rendered float or real
keystrokes must be driven in a terminal — run `nvim` inside tmux and send keys.

## Prerequisites

- `tmux` installed.
- Load only this config in a real TTY:
  `nvim --clean -u ~/.config/nvim/init.lua`. `--clean` skips user `site/`,
  `plugin/` and shada; `-u` still loads this config.

## Core harness

```bash
s=e2e
tmux kill-session -t "$s" 2>/dev/null
tmux new-session -d -s "$s" -x 200 -y 50          # fixed, deterministic size
tmux send-keys -t "$s" 'nvim --clean -u ~/.config/nvim/init.lua' C-m
sleep 3                                            # let startup/dashboard settle
# ... drive keys / luafile probes ...
tmux capture-pane -pt "$s" -S -60                  # last 60 lines of the pane
tmux kill-session -t "$s"
```

- `capture-pane -p` prints to stdout: `-t <target>`, `-S -N` includes N lines of
  scrollback. Capture after every step and grep the result.
- `send-keys` arguments are key names (`C-m` = Enter, `C-c`, `Esc`, `Up`, ...) or
  a literal string. To send a literal string with control chars, use `-l`:
  `tmux send-keys -t "$s" -l $' l\r'`.

## Reproducing keystroke races (the important case)

Never put a `sleep` between the keys of the sequence under test — the gap hides
races. Send the whole sequence in one call so it lands in the typeahead:

```bash
# <Space>l opens Lazy, then <CR>, with no delay in between
tmux send-keys -t "$s" -l $' l\r'
sleep 2
out=$(tmux capture-pane -pt "$s" -S -60)
if echo "$out" | grep -qiE 'E5108|bad argument|Aperte ENTER|Press ENTER'; then
  echo BROKEN; echo "$out" | grep -iE 'E5108|bad argument|ipairs|pairs' | tail -5
else
  echo ok
fi
```

Run several fresh sessions with **varying startup delays** (e.g. 1.5s–3.0s) to
catch timing-dependent races. Always reproduce *before* a fix and repeat the
exact sequence *after* it; a single `ok` is not evidence.

This is how the Lazy view race was found: `<Space>l` then `<CR>` with no delay
made `render:get_plugin` run before the async `render:update()` had populated
`render.locations`, producing
`E5108: ... view/render.lua:108: bad argument #1 to 'ipairs' (table expected, got nil)`.
With a `sleep` between the keys it never happened.

## Inspecting live Lua state

Drive Lua in the running TTY with `:luafile` (write a temp script under
`/tmp/opencode/`, then feed it):

```lua
-- /tmp/opencode/probe.lua
local V = require("lazy.view")
V.show()                          -- real view; works only with a TTY
local r = V.view.render
for row = 1, vim.api.nvim_buf_line_count(V.view.buf) do
  local ok, err = pcall(r.get_plugin, r, row)
  if not ok then
    print(("ROW %d ERROR: %s"):format(row, err))
  end
end
print("probe done")
```

```bash
tmux send-keys -t "$s" ':luafile /tmp/opencode/probe.lua' C-m
sleep 2
tmux capture-pane -pt "$s" -S -80 | tail -40
```

Prefer probing the object the keymaps actually use (e.g. `require("lazy.view").view`)
over stubbing modules — stubs hide require-path failures.

## Checking keymaps without a TTY

`maparg` works headless and is the fastest way to see what a key really does
(leader is `<Space>` in this config):

```bash
nvim --headless "+lua print(vim.inspect(vim.fn.maparg(' l','n',false,true)))" +qa
nvim --headless "+lua print(vim.inspect(vim.fn.maparg(' L','n',false,true)))" +qa
```

An empty result means the mapping does not exist.

## Logs and caches (when the on-screen trace disagrees with the source)

- `~/.local/state/nvim/nvim.log` — Neovim internal errors (treesitter decoration
  providers, TUI warnings). Lua callback errors shown on screen are usually NOT
  written here, so absence is not proof the error did not happen.
- `~/.cache/nvim/luac/<url-encoded-path>.luac` — LuaJIT bytecode cache. The file
  starts with an ASCII header `"<version>,<source_size>,<mtime_sec>,<mtime_nsec>\0"`
  followed by bytecode. Compare the header against `stat` of the source; if size
  and mtime match, the cache is current. (Disassemble with
  `tail -c +N file > x.ljbc && luajit -bl x.ljbc` only if you need to confirm.)
- `~/.local/state/nvim/shada/main.shada` — command history. Read it without
  clobbering it:
  `nvim --clean --headless -i <shada> "+lua for i=1,40 do local h=vim.fn.histget(':',i); if h=='' then break end; print(i..': '..h) end" +qa`.

## Gotchas

- `nvim --headless` has no UI: `:Lazy`, floats and `vim.ui` paths are skipped.
  A clean headless exit does NOT prove a UI path works.
- A leading `sleep` after launch is needed; do not sleep *inside* the key
  sequence under test.
- Use `--clean -u <init.lua>` to isolate config behavior; use plain `nvim` when
  shada/history or user runtime matters.
- Resize with `tmux resize-window -t "$s" -x W -y H` to exercise
  `VimResized`/layout code paths.
- Clean up: `tmux kill-session -t "$s"` at the end of each trial so sessions do
  not leak.
- `capture-pane` reflects the visible state; after an error prompt, an extra
  Enter dismisses it, so grep immediately after the step that should fail.

## Output

Report: the exact key sequence, the observed error (or its absence), how many
trials were run and with which startup delays, and the before/after result when
validating a fix. Pair an E2E result with the headless load check
(`nvim --headless "+lua vim.cmd('qa')"` exits 0).
