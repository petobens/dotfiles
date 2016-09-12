"===============================================================================
"          File: deoplete_rc.vim
"        Author: Pedro Ferrari
"       Created: 12 Sep 2016
" Last Modified: 12 Sep 2016
"   Description: Deoplete configuration
"===============================================================================
" Autoclose preview when completion is finished
augroup deoplete_pl
    au!
    au CompleteDone * pclose!
augroup END

" Custom settings
if dein#check_install(['deoplete']) == 0
    " Start completion after one character is typed
    call deoplete#custom#set('_', 'min_pattern_length', 1)
    " Use auto delimiter
    call deoplete#custom#set('_', 'converters',
        \ ['converter_auto_delimiter', 'remove_overlap'])
    " Show ultisnips first
    call deoplete#custom#set('ultisnips', 'rank', 1000)
endif

let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_smart_case = 1
" let g:neocomplete#min_keyword_length = 2
let g:deoplete#max_list = 150
" let g:neocomplete#data_directory = $CACHE . '/plugins/neocomplete'
" let g:neocomplete#enable_multibyte_completion = 1
" let g:neocomplete#sources#buffer#max_keyword_width = 90
let g:deoplete#enable_refresh_always = 1

" Python (jedi)
let deoplete#sources#jedi#show_docstring = 1
let g:deoplete#sources#jedi#python_path = '/usr/local/bin/python3'

" Sources used for completion
if !exists('g:deoplete#sources')
    let g:deoplete#sources = {}
endif
let g:deoplete#sources.bib = ['ultisnips']
let g:deoplete#sources.snippets = ['ultisnips']
let g:deoplete#sources.tex = ['buffer', 'dictionary', 'ultisnips', 'file',
        \ 'omni']

" Dictionaries (and function to edit them if available)
let g:deoplete#sources#dictionary#dictionaries = {
        \ 'default' : '',
        \ 'tex' : $DOTVIM.'/ftplugin/tex/tex_dictionary.dict',
        \ 'vimshell' : $DOTVIM.'/ftplugin/vimshell/vimshell_dictionary.dict'
        \ }

function! s:Edit_Dict()
    let dict_file = get(g:deoplete#sources#dictionary#dictionaries,&filetype)
    if empty(dict_file)
        echo 'No dictionary file found.'
        return
    endif
    let split_windows = 'vsplit '
    if winwidth(0) <= 2 * (&tw ? &tw : 80)
        let split_windows = 'split '
    endif
    execute split_windows . dict_file
endfunction

" Keyword patterns
if !exists('g:deoplete#keyword_patterns')
    let g:deoplete#keyword_patterns = {}
endif
let g:deoplete#keyword_patterns._ = '[A-Za-zá-úÁ-ÚñÑ_][0-9A-Za-zá-úÁ-ÚñÑ_]*'

" Custom source patterns and attributes
" FIXME: This should be Python3 regexp?
let keyword_patterns = {}
let keyword_patterns = {'tex' : '\h\w\{,2}:\%(\w*\|\w*_\w*\)\?'}
let keyword_patterns2 = {'tex' : '\\?[a-zA-Z_]\w*'}
if dein#check_install(['deoplete']) == 0
    call deoplete#custom#set('buffer', 'keyword_patterns',
            \ keyword_patterns)
    call deoplete#custom#set('dictionary', 'keyword_patterns',
            \ keyword_patterns2)
endif

" Omni patterns
if !exists('g:deoplete#sources#omni#functions')
    let g:deoplete#sources#omni#functions= {}
endif
let g:deoplete#sources#omni#functions.sql = 'sqlcomplete#Complete'

if !exists('g:deoplete#omni#input_patterns')
    let g:deoplete#omni#input_patterns = {}
endif
let g:deoplete#omni#input_patterns.tex =
        \ '\v\\\a*cite\a*([^]]*\])?\{(|[^}]*,)' .
        \ '|(includegraphics|input|include|includeonly)' .
        \ '%(\s*\[[^]]*\])?\s*\{[^{}]*'

" Mappings
if dein#check_install(['deoplete']) == 0
    " If a snippet is available enter expands it; if not available, it selects
    " current candidate and closes the popup menu (i.e it ends completion)
    inoremap <silent><expr><CR> pumvisible() ?
        \ (len(keys(UltiSnips#SnippetsInCurrentScope())) > 0 ?
        \ "\<C-y>\<C-R>=UltiSnips#ExpandSnippet()\<CR>" : "\<C-y>") : "\<CR>"
    " Close popup and delete backward character
    inoremap <expr><BS> deoplete#smart_close_popup()."\<BS>"
    " Undo completion i.e remove whole completed word (default plugin mapping)
    inoremap <expr> <C-g> deoplete#undo_completion()
endif

" Move in preview window with tab
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><s-tab> pumvisible() ? "\<c-p>" : "\<s-tab>"
" Edit dictionary files
nnoremap <silent> <Leader>ed :call <SID>Edit_Dict()<CR>
