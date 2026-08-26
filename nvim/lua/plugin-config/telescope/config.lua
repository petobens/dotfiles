local action_layout = require('telescope.actions.layout')
local actions = require('telescope.actions')
local telescope = require('telescope')

local action_config = require('plugin-config.telescope.actions')
local custom_previewers = require('plugin-config.telescope.previewers')
local customizations = require('plugin-config.telescope.customizations')
local helpers = require('plugin-config.telescope.helpers')

local M = {}

function M.setup()
    telescope.setup({
        defaults = {
            prompt_prefix = '   ',
            multi_icon = ' ',
            winblend = 7,
            results_title = false,
            color_devicons = true,
            file_ignore_patterns = { 'doc/', 'venv/', '__pycache__/' },
            layout_strategy = 'bpane',
            layout_config = {
                prompt_position = 'bottom',
                height = 20,
                preview_width = 0.45,
                preview_cutoff = 110,
            },
            cache_picker = { num_pickers = 3 },
            path_display = { 'filename_first' },
            buffer_previewer_maker = custom_previewers.buffer_maker,
            mappings = {
                i = {
                    ['<ESC>'] = 'close',
                    ['<CR>'] = helpers.stopinsert(actions.select_default),
                    ['<TAB>'] = helpers.stopinsert(actions.select_default),
                    ['<C-s>'] = helpers.stopinsert(actions.select_horizontal),
                    ['<C-v>'] = helpers.stopinsert(actions.select_vertical),
                    ['<C-j>'] = 'move_selection_next',
                    ['<C-k>'] = 'move_selection_previous',
                    ['<A-j>'] = 'preview_scrolling_down',
                    ['<A-k>'] = 'preview_scrolling_up',
                    ['<C-l>'] = action_config.custom.focus_preview,
                    ['<A-v>'] = action_layout.toggle_preview,
                    ['<A-n>'] = actions.cycle_previewers_next,
                    ['<C-space>'] = actions.toggle_selection
                        + actions.move_selection_previous,
                    ['<C-y>'] = action_config.custom.yank,
                    ['<C-t>'] = action_config.custom.entry_find_files,
                    ['<A-t>'] = action_config.custom.entry_find_files_no_ignore,
                    ['<A-c>'] = action_config.custom.entry_find_dir,
                    ['<A-f>'] = helpers.stopinsert(action_config.custom.open_nvimtree),
                    ['<A-p>'] = action_config.custom.entry_parent_dirs,
                    ['<A-g>'] = action_config.custom.entry_igrep,
                    ['<A-a>'] = helpers.stopinsert(
                        action_config.custom.add_codecompanion_references
                    ),
                    ['<A-i>'] = helpers.stopinsert(
                        action_config.custom.add_codecompanion_images
                    ),
                    ['<A-d>'] = helpers.stopinsert(
                        action_config.custom.add_codecompanion_documents
                    ),
                    ['<A-z>'] = actions.to_fuzzy_refine,
                    ['<C-q>'] = helpers.stopinsert(action_config.custom.send2qf),
                    ['<A-q>'] = actions.send_to_qflist + actions.open_qflist,
                    ['<A-u>'] = action_config.custom.resume,
                    ['<C-/>'] = 'which_key',
                    ['<A-l>'] = actions.complete_tag,
                },
                n = {
                    ['q'] = 'close',
                    ['<C-c>'] = 'close',
                    ['<Tab>'] = 'select_default',
                    ['<C-s>'] = 'file_split',
                    ['<A-j>'] = 'preview_scrolling_down',
                    ['<A-k>'] = 'preview_scrolling_up',
                    ['<C-l>'] = action_config.custom.focus_preview,
                    ['<A-v>'] = action_layout.toggle_preview,
                    ['<A-n>'] = actions.cycle_previewers_next,
                    ['<space>'] = actions.toggle_selection
                        + actions.move_selection_previous,
                    ['<C-space>'] = actions.toggle_selection
                        + actions.move_selection_previous,
                    ['<C-y>'] = action_config.custom.yank,
                    ['<C-t>'] = action_config.custom.entry_find_files,
                    ['<A-t>'] = action_config.custom.entry_find_files_no_ignore,
                    ['<A-c>'] = action_config.custom.entry_find_dir,
                    ['<A-f>'] = action_config.custom.open_nvimtree,
                    ['<A-p>'] = action_config.custom.entry_parent_dirs,
                    ['<A-g>'] = action_config.custom.entry_igrep,
                    ['<A-a>'] = action_config.custom.add_codecompanion_references,
                    ['<A-i>'] = action_config.custom.add_codecompanion_images,
                    ['<A-d>'] = action_config.custom.add_codecompanion_documents,
                    ['<A-r>'] = actions.to_fuzzy_refine,
                    ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
                    ['<A-q>'] = actions.send_to_qflist + actions.open_qflist,
                    ['<A-u>'] = action_config.custom.resume,
                    ['?'] = 'which_key',
                    ['<A-l>'] = actions.complete_tag,
                },
            },
            vimgrep_arguments = {
                'rg',
                '--hidden',
                '--color=never',
                '--no-heading',
                '--with-filename',
                '--line-number',
                '--column',
                '--smart-case',
                '--trim',
            },
        },
        pickers = {
            buffers = {
                prompt_title = 'Buffers (<C-d>:delete,<A-a>:cc-context)',
                sort_mru = true,
                mappings = {
                    i = {
                        ['<C-o>'] = action_config.custom.context_split,
                        ['<C-d>'] = action_config.custom.delete_buffer,
                    },
                },
            },
            command_history = {
                mappings = {
                    i = {
                        ['<Tab>'] = actions.edit_command_line,
                    },
                },
            },
            find_files = {
                prompt_title = 'Files (<A-c>:dir,<A-p>:parents,<A-g>:grep,'
                    .. '<A-a>:cc-context,<A-i>:cc-image,<A-d>:cc-pdf)',
                find_command = function(opts)
                    local command = {
                        'fd',
                        '--type',
                        'f',
                        '--follow',
                        '--hidden',
                        '--strip-cwd-prefix',
                        '--exclude',
                        '.git',
                    }
                    local cwd = vim.fs.normalize(opts.cwd or vim.uv.cwd())
                    local screenshots =
                        vim.fs.joinpath(vim.env.HOME, 'Pictures', 'Screenshots')
                    if cwd == screenshots then
                        return { 'sh', '-c', table.concat(command, ' ') .. ' | sort -r' }
                    end
                    return command
                end,
                mappings = {
                    i = {
                        ['<CR>'] = helpers.stopinsert(
                            action_config.custom.open_one_or_many
                        ),
                        ['<C-s>'] = helpers.stopinsert(
                            action_config.custom.context_split
                        ),
                        ['<C-f>'] = action_config.custom.focus_preview,
                        ['<A-t>'] = action_config.custom.entry_find_files_no_ignore,
                        ['<A-c>'] = action_config.custom.entry_find_dir,
                        ['<A-p>'] = action_config.custom.entry_parent_dirs,
                        ['<A-g>'] = action_config.custom.entry_igrep,
                    },
                },
            },
            git_bcommits = {
                prompt_title = 'Buffer Commits (<C-d>:delta,<C-o>:checkout,<C-y>:yank,'
                    .. '<A-r>:review,<A-c>:changelog)',
                layout_config = { preview_width = 0.55 },
                mappings = {
                    i = {
                        ['<CR>'] = action_config.custom.fugitive_open,
                        ['<C-s>'] = action_config.custom.fugitive_split,
                        ['<C-v>'] = action_config.custom.fugitive_vsplit,
                        ['<C-d>'] = action_config.custom.delta_term,
                        ['<C-o>'] = actions.git_checkout,
                        ['<A-r>'] = action_config.custom.codecompanion_code_review,
                        ['<A-c>'] = action_config.custom.codecompanion_changelog,
                    },
                },
            },
            git_commits = {
                prompt_title = 'Commits (<C-d>:delta,<C-o>:checkout,<C-y>:yank,'
                    .. '<A-r>:review,<A-c>:changelog)',
                layout_config = { preview_width = 0.55 },
                mappings = {
                    i = {
                        ['<CR>'] = action_config.custom.fugitive_open,
                        ['<C-s>'] = action_config.custom.fugitive_split,
                        ['<C-v>'] = action_config.custom.fugitive_vsplit,
                        ['<C-d>'] = action_config.custom.delta_term,
                        ['<C-o>'] = actions.git_checkout,
                        ['<A-r>'] = action_config.custom.codecompanion_code_review,
                        ['<A-c>'] = action_config.custom.codecompanion_changelog,
                    },
                },
            },
            live_grep = {
                prompt_title = 'Grep (<C-space>:select,<A-a>:cc-context)',
                path_display = { shorten = 3 },
                mappings = {
                    i = {
                        ['<CR>'] = helpers.stopinsert(
                            action_config.custom.open_one_or_many
                        ),
                        ['<C-space>'] = actions.toggle_selection
                            + actions.move_selection_previous,
                    },
                },
            },
            lsp_document_symbols = {
                prompt_title = 'Document Symbols (<C-x>:complete)',
                mappings = {
                    i = {
                        ['<C-x>'] = actions.complete_tag,
                    },
                },
            },
            lsp_workspace_symbols = {
                prompt_title = 'Workspace Symbols (<C-x>:complete)',
                mappings = {
                    i = {
                        ['<C-x>'] = actions.complete_tag,
                    },
                },
            },
            quickfix = { entry_maker = customizations.quickfix_entry_maker },
            search_history = {
                mappings = {
                    i = {
                        ['<Tab>'] = action_config.custom.edit_search_line,
                    },
                },
            },
            spell_suggest = {
                prompt_title = 'Spelling Suggestions (<CR>:fix word,<C-o>:fix all)',
                mappings = {
                    i = {
                        ['<C-o>'] = action_config.custom.spell_fix_all,
                    },
                },
            },
        },
        extensions = {
            frecency = {
                auto_validate = true,
                db_validate_threshold = 2,
                db_safe_mode = false,
                matcher = 'default',
            },
            fzf = {
                fuzzy = true,
                override_generic_sorter = true,
                override_file_sorter = true,
                case_mode = 'smart_case',
            },
            thesaurus = {
                provider = 'dictionaryapi', -- or 'datamuse'
            },
            undo = {
                prompt_title = 'Undo (<C-y>:yank,<C-r>:restore)',
                layout_config = { preview_width = 0.7 },
                mappings = {
                    i = {
                        ['<C-y>'] = require('telescope-undo.actions').yank_additions,
                        ['<C-r>'] = require('telescope-undo.actions').restore,
                    },
                },
            },
        },
    })
end

return M
