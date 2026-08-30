# Dotfiles

This file provides guidance to coding agents when working in this repository.

This is a personal dotfiles repository containing configuration for multiple
tools and environments. Each top-level directory corresponds to a specific tool
or environment, for example `nvim/`, `python/`, and `arch/`.

## General rules

- Do exactly what was asked; avoid unrelated changes.
- Prefer editing existing files over creating new ones.
- Explain non-trivial code or configuration choices when they affect future
  maintenance.
- When a package or plugin lookup reports a DNS or network failure, treat any
  subsequent "not found" output as inconclusive. Retry with network access when
  available; otherwise report that the lookup could not be verified.

### Linting and formatting

- For persisted user-facing code files, run the relevant formatter and linter
  using this repository's existing tools and commands. This does not apply to
  temporary scratch files or scripts created during agent work.
- For Markdown files, run `rumdl check <file>` and keep lines at 80 characters
  or fewer. Wrap at natural boundaries while preserving valid Markdown syntax.
- For Python scripts, use Ruff (`ruff format <file>` and `ruff check --fix
<file>`) and type-check with `zmypy`, falling back to `mypy` if `zmypy` is
  not installed. Add short module or function docstrings when they clarify
  purpose or usage, but do not add boilerplate docstrings for obvious one-off
  code.
- For Bash scripts, run `shfmt -w -i 4 -ci -sr <file>` and
  `shellcheck <file>`.
- For Fish scripts, run `fish_indent -w <file>` and
  `fish --no-execute <file>`.

## Neovim (`nvim/`)

All Neovim configuration lives in the `nvim/` directory. The following rules
apply only when working inside that directory.

Ignore `nvim/cache/` for all purposes. Do not parse it, search it, or inspect
files inside it unless explicitly asked to do so.

### References

- Neovim Lua API: `/usr/share/nvim/runtime/doc/lua.txt`
- Neovim C API: `/usr/share/nvim/runtime/doc/api.txt`
- Plugin sources (vim.pack): `~/.local/share/nvim/site/pack/core/opt/`

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
luacheck --config="$HOME/.config/.luacheckrc" -- <file>
```

The configuration already declares `vim` as a global. Do not add
`--globals vim`; without an option terminator, Luacheck can consume file paths
as additional global names.

If `luacheck` or `lauc` is broken because of the Arch Lua packaging mismatch
(the `/usr/bin/luacheck` wrapper targets a Lua version whose rock tree no
longer exists), use this fallback, which derives the installed version from the
rock path so it survives package bumps:

```bash
entry=$(printf '%s\n' /usr/lib/luarocks/rocks-*/luacheck/*/bin/luacheck | head -1)
ver=$(echo "$entry" | grep -oP 'rocks-\K[0-9]+\.[0-9]+')
"lua$ver" \
    -e "package.path='/usr/share/lua/$ver/?.lua;/usr/share/lua/$ver/?/init.lua;'..package.path" \
    -e "package.cpath='/usr/lib/lua/$ver/?.so;'..package.cpath" \
    "$entry" --config="$HOME/.config/.luacheckrc" -- <file>
```

Run Luacheck on touched Lua files when making changes under `nvim/`.

#### Headless validation

For isolated Neovim API probes, use `nvim --clean --headless`. When loading the
real configuration, run from a temporary directory and redirect writable state
and cache paths:

```bash
test_dir=$(mktemp -d)
(
    cd "$test_dir"
    XDG_STATE_HOME="$test_dir/state" \
    XDG_CACHE_HOME="$test_dir/cache" \
        timeout 120 nvim --headless -c 'set shadafile=NONE' <commands>
)
```

Do not request broader filesystem permissions merely to let a headless check
write logs or cache under the home directory. Do not set `XDG_DATA_HOME` for
ordinary integration checks because the real configuration needs the installed
plugins. Keep ShaDa disabled because this configuration stores it under
`~/.config/nvim/cache`.

### Code conventions

- **APIs:** prefer the `vim` module, including `vim.fs`, `vim.system`,
  `vim.api`, `vim.keymap.set`, and `vim.opt`, over legacy Vimscript functions
  such as `vim.fn`. Use `vim.fn` only when no Lua equivalent exists or when it
  is significantly simpler.
- **Ex commands:** always use the function-style form,
  `vim.cmd.sleep('3m')`, never the string form, `vim.cmd('sleep 3m')`.
- **Descriptions:** always provide a short, meaningful `desc` for
  `vim.keymap.set` and `vim.api.nvim_create_autocmd`. For `<Leader>` mappings,
  expose the mnemonic with bracketed key letters, preserving historical
  Vim/plugin terminology when it explains the mapping. Apply the same bracketed
  mnemonic convention to LuaSnip descriptions; symbol-only triggers are already
  self-describing and do not need brackets.
- **Single-command mappings:** pass the command function directly:

  ```lua
  vim.keymap.set('n', '<Leader>sp', vim.cmd.split, { desc = '[Sp]lit horizontally' })
  ```

### Formatting rules

- Use 4-column indentation.
- Use single quotes.
- Keep lines within 90 columns.
