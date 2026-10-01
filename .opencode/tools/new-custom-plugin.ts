import { tool } from "@opencode-ai/plugin"
import { existsSync, mkdirSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"

const spec = `return {
  event = { "VeryLazy" },
  opts = {},
}
`

const entry = `local M = {}

local configured = false

function M.setup(opts)
  if configured then
    return
  end
  configured = true
  opts = opts or {}
end

return M
`

export default tool({
  description:
    'Scaffold a local ("custom") Neovim plugin: core/plugins/<name>.lua plus core/custom/<name>/lua/<name>/init.lua.',
  args: {
    name: tool.schema
      .string()
      .regex(/^[a-z][a-z0-9-]*$/)
      .describe("Plugin/module name; must match [a-z][a-z0-9-]*"),
    force: tool.schema.boolean().optional().describe("Overwrite existing files"),
  },
  async execute(args, context) {
    const name = args.name
    const pluginDir = join(context.worktree, "core", "custom", name)
    const specFile = join(context.worktree, "core", "plugins", `${name}.lua`)

    if (!args.force && (existsSync(pluginDir) || existsSync(specFile))) {
      throw new Error(`"${name}" already exists (use force: true to overwrite)`)
    }

    mkdirSync(join(pluginDir, "lua", name), { recursive: true })
    mkdirSync(dirname(specFile), { recursive: true })
    writeFileSync(specFile, spec)
    writeFileSync(join(pluginDir, "lua", name, "init.lua"), entry)

    return [
      `created core/plugins/${name}.lua`,
      `created core/custom/${name}/lua/${name}/init.lua`,
      "next: restart Neovim (or :Lazy reload) — the collector picks it up automatically",
    ].join("\n")
  },
})
