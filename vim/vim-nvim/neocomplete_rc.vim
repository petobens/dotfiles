"===============================================================================
"          File: neocomplete_rc.vim
"        Author: Pedro Ferrari
"       Created: 12 Sep 2016
" Last Modified: 12 Sep 2016
"   Description: Neocomplete configuration
"===============================================================================
let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#enable_fuzzy_completion = 1
let g:neocomplete#enable_auto_select = 1
let g:neocomplete#enable_auto_delimiter = 1
let g:neocomplete#min_keyword_length = 2
let g:neocomplete#auto_completion_start_length = 1
let g:neocomplete#enable_auto_close_preview = 1
let g:neocomplete#max_list = 100
let g:neocomplete#data_directory = $CACHE . '/plugins/neocomplete'
let g:neocomplete#enable_multibyte_completion = 1
let g:neocomplete#sources#buffer#max_keyword_width = 90
let g:neocomplete#enable_refresh_always = 1

" Sources used for completion
if !exists('g:neocomplete#sources')
    let g:neocomplete#sources = {}
endif
let g:neocomplete#sources.bib = ['ultisnips']
let g:neocomplete#sources.snippets = ['ultisnips']
let g:neocomplete#sources.tex = ['buffer', 'dictionary', 'ultisnips', 'file',
        \ 'omni']

" Dictionaries (and function to edit them if available)
let g:neocomplete#sources#dictionary#dictionaries = {
        \ 'default' : '',
        \ 'tex' : $DOTVIM.'/ftplugin/tex/tex_dictionary.dict',
        \ 'vimshell' : $DOTVIM.'/ftplugin/vimshell/vimshell_dictionary.dict'
        \ }

function! s:Edit_Dict()
    let dict_file = get(g:neocomplete#sources#dictionary#dictionaries,&filetype)
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
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns._ = '[A-Za-zá-úÁ-ÚñÑ_][0-9A-Za-zá-úÁ-ÚñÑ_]*'

" Custom source patterns and attributes
" FIXME: Pattern for python or vim files should be the initial value and not
" default value: try echo neocomplete#get_keyword_pattern('python','buffer');
" See issue #207; NO FIX
let keyword_patterns = {}
let keyword_patterns = {'tex' : '\h\w\{,2}:\%(\w*\|\w*_\w*\)\?'}
let keyword_patterns2 = {'tex' : '\\\?\h\w*'}
if dein#check_install(['neocomplete']) == 0
    " FIXME: Buffer completion and ultisnips don't play well see #390
    call neocomplete#custom#source('buffer', 'keyword_patterns',
            \ keyword_patterns)
    call neocomplete#custom#source('dictionary', 'keyword_patterns',
            \ keyword_patterns2)
    " FIXME: Ultisnips source will not show triggers after non-word characters
    " or in the middle of words (UltiSnip#SnippetsInCurrentScope fails);
    " See Ultisnips issue #330; NO FIX
    call neocomplete#custom#source('ultisnips', 'rank', 1000)
endif

" Omni patterns
if !exists('g:neocomplete#sources#omni#functions')
    let g:neocomplete#sources#omni#functions= {}
endif
let g:neocomplete#sources#omni#functions.sql = 'sqlcomplete#Complete'

if !exists('g:neocomplete#force_omni_input_patterns')
    let g:neocomplete#force_omni_input_patterns = {}
endif
let g:neocomplete#force_omni_input_patterns.tex =
        \ '\v\\\a*cite\a*([^]]*\])?\{(|[^}]*,)' .
        \ '|(includegraphics|input|include|includeonly)' .
        \ '%(\s*\[[^]]*\])?\s*\{[^{}]*'
let g:neocomplete#force_omni_input_patterns.python =
    \ '\%([^. \t]\.\|^\s*@\|^\s*from\s.\+import \|^\s*from \|^\s*import \)\w*'

" Mappings
if dein#check_install(['neocomplete']) == 0
    " If a snippet is available enter expands it; if not available, it selects
    " current candidate and closes the popup menu (i.e it ends completion)
    inoremap <silent><expr><CR> pumvisible() ?
        \ (len(keys(UltiSnips#SnippetsInCurrentScope())) > 0 ?
        \ "\<C-y>\<C-R>=UltiSnips#ExpandSnippet()\<CR>" : "\<C-y>") : "\<CR>"
    " Close popup and delete backward character
    inoremap <expr><BS> neocomplete#smart_close_popup()."\<BS>"
    " Undo completion i.e remove whole completed word (default plugin mapping)
    inoremap <expr> <C-g> neocomplete#undo_completion()
endif

" Move in preview window with tab
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<S-TAB>"
" Neocomplete cache
nnoremap <silent> <Leader>nc :NeoCompleteClean\|NeoCompleteBufferMakeCache\|
            \ NeoCompleteDictionaryMakeCache<CR>
" Edit dictionary files
nnoremap <silent> <Leader>ed :call <SID>Edit_Dict()<CR>
