#!/usr/bin/env node
// Scaffold a local ("custom") plugin: core/plugins/<name>.lua + core/custom/<name>/.
// Requires Node 23+ (native TypeScript type-stripping; no build step).
//
// Usage: node .opencode/tools/new-custom-plugin.ts <name> [--force]

import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

const root = resolve(import.meta.dirname, "..", "..");
const args = process.argv.slice(2);
const force = args.includes("--force");
const name = args.find((arg) => !arg.startsWith("--"));

function die(message: string): never {
  console.error(`error: ${message}`);
  process.exit(1);
}

if (!name) {
  die("usage: node .opencode/tools/new-custom-plugin.ts <name> [--force]");
}

if (!/^[a-z][a-z0-9-]*$/.test(name)) {
  die(`invalid name "${name}" (must match [a-z][a-z0-9-]*)`);
}

const pluginDir = join(root, "core", "custom", name);
const specFile = join(root, "core", "plugins", `${name}.lua`);

if (!force && (existsSync(pluginDir) || existsSync(specFile))) {
  die(`"${name}" already exists (use --force to overwrite)`);
}

const spec = `return {
  event = { "VeryLazy" },
  opts = {},
}
`;

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
`;

mkdirSync(join(pluginDir, "lua", name), { recursive: true });
mkdirSync(dirname(specFile), { recursive: true });
writeFileSync(specFile, spec);
writeFileSync(join(pluginDir, "lua", name, "init.lua"), entry);

console.log(`created core/plugins/${name}.lua`);
console.log(`created core/custom/${name}/lua/${name}/init.lua`);
console.log("next: restart Neovim (or :Lazy reload) — the collector picks it up automatically");
