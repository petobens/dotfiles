"===============================================================================
"          File: deoplete_rc.vim
"        Author: Pedro Ferrari
"       Created: 12 Sep 2016
" Last Modified: 15 Sep 2016
"   Description: Deoplete configuration
"===============================================================================
" Autoclose preview when completion is finished
augroup ps_deoplete
    au!
    au CompleteDone * pclose!
augroup END

" Custom settings
if dein#check_install(['deoplete']) == 0
    " Start completion after two characters are typed (this is the default)
    " Note: if we explicitly set this then auto file completion is lost
    " call deoplete#custom#set('_', 'min_pattern_length', 2)
    " Use auto delimiter
    call deoplete#custom#set('_', 'converters',
        \ ['converter_auto_delimiter', 'remove_overlap',
        \ 'converter_auto_paren'])
    " Show ultisnips first and activate completion after 1 character
    call deoplete#custom#set('ultisnips', 'rank', 1000)
    call deoplete#custom#set('ultisnips', 'min_pattern_length', 1)
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

" Custom source patterns and attributes (note this is a python3 regex and not a
" vim one)
let tex_buffer_patterns = {'tex' : '\w{2,}:\S+'}
let tex_dict_patterns = {'tex' : '\\?[a-zA-Z_]\w*'}
if dein#check_install(['deoplete']) == 0
    call deoplete#custom#set('buffer', 'keyword_patterns',
            \ tex_buffer_patterns)
    call deoplete#custom#set('dictionary', 'keyword_patterns',
            \ tex_dict_patterns)
endif

" Omni patterns
" if !exists('g:deoplete#omni_patterns')
    " let g:deoplete#omni_patterns = {}
" endif
" let g:deoplete#omni_patterns.tex ='\v\\\a*cite\a*([^]]*\])?\{(|[^}]*,)' .
        " \ '|(includegraphics|input|include|includeonly)' .
        " \ '%(\s*\[[^]]*\])?\s*\{[^{}]*'

" FIXME: If we enable omni we lose dictionary completion
" if !exists('g:deoplete#omni#input_patterns')
    " let g:deoplete#omni#input_patterns = {}
" endif
" let g:deoplete#omni#input_patterns.tex = '\\(?:'
    " \ .  '\w*cite\w*(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
    " \ . '|\w*ref(?:\s*\{[^}]*|range\s*\{[^,}]*(?:}{)?)'
    " \ . '|includegraphics\*?(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*'
    " \ . '|(?:include(?:only)?|input)\s*\{[^}]*'
    " \ .')'

" Mappings
if dein#check_install(['deoplete']) == 0
    " Close popup and delete backward character
    inoremap <expr><BS> deoplete#smart_close_popup()."\<BS>"
    " Undo completion i.e remove whole completed word (default plugin mapping)
    inoremap <expr> <C-g> deoplete#undo_completion()
endif
