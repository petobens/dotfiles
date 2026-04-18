# Dotfiles

This file provides guidance to coding agents when working in this repository.

This is a personal dotfiles repository containing configuration for multiple
tools and environments. Each top-level directory corresponds to a specific tool
or environment, for example `nvim/`, `python/`, and `arch/`.

## Neovim (`nvim/`)

All Neovim configuration lives in the `nvim/` directory. The following rules
apply only when working inside that directory.

Ignore `nvim/cache/` for all purposes. Do not parse it, search it, or inspect
files inside it unless explicitly asked to do so.

### References

- Neovim Lua API: `/usr/share/nvim/runtime/doc/lua.txt`
- Neovim C API: `/usr/share/nvim/runtime/doc/api.txt`
- Plugin sources (lazy.nvim): `~/.local/share/nvim/lazy/`

Consult these before answering questions about Neovim APIs or plugin internals.

### Commands

#### Formatting

```bash
stylua \
  --config-path ~/git-repos/private/dotfiles/linters/stylua.toml \
  <file>
```

Run this before committing changes to Neovim Lua files.

#### Linting

Preferred command:

```bash
luacheck --config ~/.config/.luacheckrc --globals vim <file>
```

If `luacheck` or `lauc` is broken because of the Arch Lua packaging mismatch,
use the same fallback as
`nvim/lua/plugin-config/nvimlint_config.lua`:

```bash
lua5.4 -e "package.path='/usr/share/lua/5.5/?.lua;/usr/share/lua/5.5/?/init.lua;'..package.path; package.cpath='/usr/lib/lua/5.4/?.so;'..package.cpath; dofile('/usr/lib/luarocks/rocks-5.5/luacheck/1.2.0-1/bin/luacheck')" -- --config ~/.config/.luacheckrc --globals vim -- <file>
```

Run Luacheck on touched Lua files when making changes under `nvim/`.

### Code conventions

- **APIs:** prefer the `vim` module, including `vim.fs`, `vim.system`,
  `vim.api`, `vim.keymap.set`, and `vim.opt`, over legacy Vimscript functions
  such as `vim.fn`. Use `vim.fn` only when no Lua equivalent exists or when it
  is significantly simpler.
- **Ex commands:** always use the function-style form,
  `vim.cmd.sleep('3m')`, never the string form, `vim.cmd('sleep 3m')`.
- **Descriptions:** always provide a short, meaningful `desc` for
  `vim.keymap.set` and `vim.api.nvim_create_autocmd`.
- **Single-command mappings:** pass the command function directly:

  ```lua
  vim.keymap.set('n', '<Leader>sp', vim.cmd.split, { desc = 'Horizontal split' })
  ```

### Formatting rules

- Use 4-column indentation.
- Use single quotes.
- Keep lines within 90 columns.

## General rules

- Do what has been asked, nothing more and nothing less.
- Prefer editing existing files over creating new ones.
- Explain code when appropriate, especially for non-trivial examples.
- When writing or editing Markdown files, keep lines at 80 characters or fewer.
  Wrap at natural boundaries while preserving valid Markdown syntax.
