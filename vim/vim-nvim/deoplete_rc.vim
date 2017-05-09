"===============================================================================
"          File: deoplete_rc.vim
"        Author: Pedro Ferrari
"       Created: 12 Sep 2016
" Last Modified: 08 May 2017
"   Description: Deoplete configuration
"===============================================================================
" Autoclose preview when completion is finished
augroup ps_deoplete
    au!
    au CompleteDone * pclose!
augroup END

" Custom settings
if dein#tap('deoplete') == 1
    " Start completion after two characters are typed (this is the default)
    " Note: if we explicitly set this then auto file completion is lost
    " call deoplete#custom#set('_', 'min_pattern_length', 2)
    " Use auto delimiter and autoparen (not in omni source)
    call deoplete#custom#set('_', 'converters',
        \ ['converter_auto_delimiter', 'remove_overlap',
        \ 'converter_auto_paren'])
    call deoplete#custom#set('omni', 'converters',
        \ ['converter_auto_delimiter', 'remove_overlap'])
    " Show ultisnips first and activate completion after 1 character
    call deoplete#custom#set('ultisnips', 'rank', 1000)
    call deoplete#custom#set('ultisnips', 'min_pattern_length', 1)
    " Extend max candidate width in popup menu for buffer source
    call deoplete#custom#set('buffer', 'max_menu_width', 90)
    " Complete dictionary after one character
    call deoplete#custom#set('dictionary', 'min_pattern_length', 1)
endif

let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#max_list = 150
let g:deoplete#enable_refresh_always = 1
let g:deoplete#auto_complete_delay = 50

" Python (jedi)
let deoplete#sources#jedi#show_docstring = 1

" Sources used for completion
if !exists('g:deoplete#sources')
    let g:deoplete#sources = {}
endif
let g:deoplete#sources.bib = ['ultisnips']
let g:deoplete#sources.snippets = ['ultisnips']
let g:deoplete#sources.tex = ['buffer', 'dictionary', 'ultisnips', 'file',
        \ 'omni']

" Custom source patterns and attributes (note this is a python3 regex and not a
" vim one)
let tex_buffer_patterns = {'tex' : '[a-zA-Z_]\w{2,}:\S+'}
let tex_dict_patterns = {'tex' : '\\?[a-zA-Z_]\w*'}
if dein#tap('deoplete') == 1
    call deoplete#custom#set('buffer', 'keyword_patterns',
            \ tex_buffer_patterns)
    call deoplete#custom#set('dictionary', 'keyword_patterns',
            \ tex_dict_patterns)
endif

" Omni completion (for tex it requires vimtex plugin)
if !exists('g:deoplete#omni#input_patterns')
    let g:deoplete#omni#input_patterns = {}
endif
let g:deoplete#omni#input_patterns.tex = '\\(?:'
    \ .  '\w*cite\w*(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
    \ . '|includegraphics\*?(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*'
    \ . '|(?:include(?:only)?|input)\s*\{[^}]*'
    \ . '|usepackage(\s*\[[^]]*\])?\s*\{[^}]*'
    \ . '|documentclass(\s*\[[^]]*\])?\s*\{[^}]*'
    \ .')'
let g:deoplete#omni#input_patterns.gitcommit = '((?:F|f)ix(?:es)?\s|'
    \ . '(?:C|c)lose(?:s)?\s|(?:R|r)esolve(?:s)?\s|(?:S|s)ee\s)\S*'

" Mappings
if dein#tap('deoplete') == 1
    " Close popup and delete backward character
    inoremap <expr><BS> deoplete#smart_close_popup()."\<BS>"
    " Undo completion i.e remove whole completed word (default plugin mapping)
    inoremap <expr> <C-g> deoplete#undo_completion()
endif
