local builtin = require('telescope.builtin')
local telescope = require('telescope')
local utils = require('telescope.utils')

local pickers = require('plugin-config.telescope.pickers')
local u = require('utils')

local M = {}

function M.setup()
    -- Picker management
    vim.keymap.set('n', '<Leader>dr', function()
        vim.cmd.Telescope('resume')
    end, { desc = '[D]enite [r]esume: last Telescope picker' })

    vim.keymap.set('n', '<Leader>tp', function()
        vim.cmd.Telescope('pickers')
    end, { desc = '[T]elescope [p]ickers' })

    vim.keymap.set('n', '<Leader>tq', function()
        vim.cmd.Telescope('quickfix')
    end, { desc = '[T]elescope [q]uickfix' })

    -- Files and directories
    vim.keymap.set('n', '<Leader>be', builtin.buffers, { desc = '[B]uffers: [e]xplore' })

    vim.keymap.set(
        'n',
        '<Leader>ls',
        pickers.find_files_cwd,
        { desc = '[L]ist files in [s]ame directory as buffer' }
    )

    vim.keymap.set('n', '<Leader>lS', function()
        pickers.find_files_cwd({ no_ignore = true })
    end, { desc = '[L]ist all files in [S]ame directory as buffer' })

    vim.keymap.set(
        'n',
        '<Leader>lu',
        pickers.find_files_upper_cwd,
        { desc = '[L]ist files one level [u]p' }
    )

    vim.keymap.set('n', '<Leader>lU', function()
        pickers.find_files_upper_cwd({ no_ignore = true })
    end, { desc = '[L]ist all files one level [U]p' })

    vim.keymap.set('n', '<Leader>sd', function()
        vim.cmd.lcd(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
        vim.api.nvim_input(':Telescope find_files cwd=')
    end, { desc = '[S]can [d]irectory for files' })

    vim.keymap.set(
        { 'n', 'i' },
        '<C-t>',
        pickers.find_files_cwd,
        { desc = 'Telescope: Find files in buffer dir' }
    )

    vim.keymap.set('n', '<A-t>', function()
        pickers.find_files_cwd({ no_ignore = true })
    end, { desc = 'Telescope: Find all files in buffer dir' })

    vim.keymap.set(
        'n',
        '<Leader>rd',
        pickers.frecent_files,
        { desc = '[R]ecent [d]ocuments (frecent)' }
    )

    vim.keymap.set(
        'n',
        '<A-c>',
        pickers.find_dirs,
        { desc = 'Telescope: Find directories' }
    )

    vim.keymap.set(
        'n',
        '<A-p>',
        pickers.parent_dirs,
        { desc = 'Telescope: Parent directories' }
    )

    vim.keymap.set(
        'n',
        '<Leader>bm',
        pickers.bookmark_dirs,
        { desc = '[B]ook[m]arks: directories' }
    )

    vim.keymap.set(
        { 'n', 'i' },
        '<A-z>',
        pickers.z_with_tree_preview,
        { desc = 'Telescope: Zoxide with tree preview' }
    )

    -- Search and grep
    vim.keymap.set(
        'n',
        '<Leader>ig',
        pickers.igrep,
        { desc = '[I]nteractive [g]rep in buffer directory' }
    )

    vim.keymap.set('n', '<Leader>iG', function()
        pickers.igrep(nil, nil, { '--no-ignore-vcs' })
    end, { desc = '[I]nteractive [G]rep (no VCS ignore)' })

    vim.keymap.set(
        'n',
        '<A-g>',
        pickers.igrep,
        { desc = 'Telescope: Live grep in buffer dir' }
    )

    vim.keymap.set('n', '<Leader>ir', function()
        local git_root = u.git_root(utils.buffer_dir())
        if not git_root then
            vim.notify('Current buffer is not in a git repository', vim.log.levels.WARN)
            return
        end
        pickers.igrep(git_root)
    end, { desc = '[I]nteractive grep in git [r]oot' })

    vim.keymap.set('n', '<Leader>io', function()
        builtin.live_grep({ grep_open_files = true, results_title = 'Open Files' })
    end, { desc = '[I]nteractive grep in [o]pen files' })

    vim.keymap.set(
        'n',
        '<Leader>rg',
        pickers.rgrep,
        { desc = '[R]ecursive [g]rep: prompt for directory' }
    )

    vim.keymap.set('n', '<Leader>rG', function()
        pickers.rgrep({ '--no-ignore-vcs' })
    end, { desc = '[R]ecursive [G]rep: prompt for directory (no VCS ignore)' })

    vim.keymap.set({ 'n', 'v' }, '<Leader>dg', function()
        pickers.igrep(nil, u.get_selection())
    end, { desc = '[D]enite [g]rep: selection in buffer directory' })

    vim.keymap.set(
        'n',
        '<Leader>dl',
        pickers.search_buffer,
        { desc = '[D]enite [l]ines: fuzzy find in buffer' }
    )

    vim.keymap.set({ 'n', 'v' }, '<Leader>dw', function()
        pickers.search_buffer(u.get_selection())
    end, { desc = '[D]enite [w]ord: fuzzy find selection in buffer' })

    vim.keymap.set('n', '<Leader>tl', function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        builtin.grep_string({
            results_title = buf_name,
            use_regex = true,
            search = 'TODO:\\s|FIXME:\\s',
            search_dirs = { buf_name },
        })
    end, { desc = '[T]ODOs [l]ocal to current file' })

    vim.keymap.set('n', '<Leader>tL', function()
        local buffer_dir = utils.buffer_dir()
        builtin.grep_string({
            cwd = buffer_dir,
            results_title = buffer_dir,
            use_regex = true,
            search = 'TODO:\\s|FIXME:\\s',
        })
    end, { desc = '[T]ODOs [L]ocal to buffer directory' })

    -- Git
    vim.keymap.set(
        'n',
        '<Leader>gl',
        pickers.gitcommits,
        { desc = '[G]it [l]og (repository)' }
    )

    vim.keymap.set(
        'n',
        '<Leader>gL',
        pickers.gitcommits_buffer,
        { desc = '[G]it [L]og (buffer)' }
    )

    vim.keymap.set(
        'v',
        '<Leader>gl',
        builtin.git_bcommits_range,
        { desc = '[G]it [l]og commits (visual range)' }
    )

    vim.keymap.set('n', '<Leader>gc', function()
        builtin.git_branches({ prompt_title = 'Git Branches (<C-d>:delete)' })
    end, { desc = '[G]it bran[c]hes' })

    -- History
    vim.keymap.set('n', '<Leader>ch', function()
        builtin.command_history({ prompt_title = 'Command History (<Tab>:edit)' })
    end, { desc = '[C]ommand [h]istory' })

    vim.keymap.set('n', '<Leader>sh', function()
        builtin.search_history({ prompt_title = 'Search History (<Tab>:edit)' })
    end, { desc = '[S]earch [h]istory' })

    vim.keymap.set('n', '<Leader>yh', function()
        telescope.extensions.neoclip.default({
            prompt_title = 'Neoclip: Register + (<C-d>:delete,<C-q>:replay,'
                .. '<C-y>:yank,<CR>:paste)',
            preview_title = 'Yank History Preview',
        })
    end, { desc = '[Y]ank [h]istory (Neoclip)' })

    -- Editor tools
    vim.keymap.set(
        'n',
        '<Leader>he',
        builtin.help_tags,
        { desc = '[H]elp [e]ntries (tags)' }
    )

    vim.keymap.set(
        'n',
        '<Leader>th',
        builtin.highlights,
        { desc = '[T]elescope [h]ighlight groups' }
    )

    vim.keymap.set('n', '<Leader>tm', builtin.marks, { desc = '[T]elescope [m]arks' })

    vim.keymap.set(
        'n',
        '<Leader>me',
        builtin.keymaps,
        { desc = '[M]appings: [e]xplore all' }
    )

    vim.keymap.set('n', '<Leader>mE', function()
        builtin.keymaps({ only_buf = true, prompt_title = 'Buffer-local keymaps' })
    end, { desc = '[M]appings: [E]xplore buffer-local' })

    vim.keymap.set('n', '<Leader>sg', function()
        builtin.spell_suggest({
            fuzzy = false,
        })
    end, { desc = '[S]pelling: [g]et suggestions' })

    -- Symbols and references
    vim.keymap.set('n', '<Leader>la', function()
        builtin.lsp_references({
            preview_title = 'LSP References Preview',
            jump_type = 'split',
            fname_width = 50,
        })
    end, { desc = '[L]SP [a]ppearances/references' })

    vim.keymap.set('n', '<Leader>te', function()
        builtin.lsp_document_symbols({
            results_title = vim.api.nvim_buf_get_name(0),
            preview_title = 'LSP Document Symbols Preview',
        })
    end, { desc = '[T]ag [e]ntries: LSP document symbols' })

    vim.keymap.set('n', '<Leader>we', function()
        builtin.lsp_workspace_symbols({
            preview_title = 'LSP Workspace Symbols Preview',
        })
    end, { desc = '[W]orkspace [e]ntries: LSP symbols' })

    vim.keymap.set('n', '<Leader>ta', function()
        require('telescope').extensions.aerial.aerial({
            prompt_title = 'Aerial Document Symbols',
        })
    end, { desc = '[T]elescope [a]erial document symbols' })

    -- Utilities
    vim.keymap.set('n', '<Leader>gu', function()
        require('telescope').extensions.undo.undo({
            preview_title = 'Undo Diff',
        })
    end, { desc = '[G]undo [u]ndo tree (Telescope)' })

    vim.keymap.set(
        'n',
        '<Leader>tt',
        pickers.thesaurus_synonyms,
        { desc = '[T]elescope [t]hesaurus synonyms' }
    )
end

return M
