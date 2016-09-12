"===============================================================================
"          File: powerline.vim
"        Author: Pedro Ferrari
"       Created: 20 ago 2013
" Last Modified: 06 Feb 2015
"   Description: Powerline Airline Theme
"===============================================================================
let g:airline#themes#powerline#palette = {}

" The first element of the list is the foreground color and the second one the
" background color
let g:airline#themes#powerline#palette.normal = {
      \ 'airline_a':       ['#005f00', '#afd700',  22, 148, 'bold'],
      \ 'airline_b':       ['#bcbcbc', '#4e4e4e', 250, 239, ''],
      \ 'airline_c':       ['#f8f6f2', '#303030',  15, 236, ''],
      \ 'airline_x':       ['#9e9e9e', '#303030', 247, 236, ''],
      \ 'airline_y':       ['#bcbcbc', '#4e4e4e', 250, 239, ''],
      \ 'airline_z':       ['#303030', '#d0d0d0', 236, 252, ''],
      \ 'airline_warning': ['#141413', '#df5f00', 232, 166, ''],
      \ }
let g:airline#themes#powerline#palette.normal_paste = {
      \ 'airline_a': ['#f8f6f2', '#d70000', 15, 160, 'bold']
      \ }

let g:airline#themes#powerline#palette.insert = {
      \ 'airline_a': ['#141413', '#0a9dff', 232, 39, 'bold']
      \ }

let g:airline#themes#powerline#palette.visual = {
      \ 'airline_a': ['#870000', '#ff8700', 88, 208, 'bold']
      \ }

let g:airline#themes#powerline#palette.replace = {
      \ 'airline_a': ['#f8f6f2', '#d70000', 15, 160, 'bold']
      \ }

let s:IA   = ['#4e4e4e', '#262626', 239, 235, '']
let g:airline#themes#powerline#palette.inactive =
            \ airline#themes#generate_color_map(s:IA, s:IA, s:IA)

" Readonly
let g:airline#themes#powerline#palette.accents = {
    \ 'red': ['#ff5f5f', '#303030', 203, 236]
    \ }

let g:airline#themes#powerline#palette.tabline = {
      \ 'airline_tab':           ['#bcbcbc', '#444444', 250, 238, ''],
      \ 'airline_tabsel':        ['#141413', '#0a9dff', 232,  39, 'bold'],
      \ 'airline_tabfill':       ['#f8f6f2', '#303030',  15, 236, ''],
      \ 'airline_tabtype':       ['#303030', '#d0d0d0', 236, 252, 'bold'],
      \ 'airline_tabmod':        ['#f8f6f2', '#d70000',  15, 160, 'bold'],
      \ 'airline_tabmod_unsel':  ['#141413', '#df5f00', 232, 166, 'bold'],
      \ 'airline_tabhid':        ['#585858', '#262626', 240, 235, '']
      \ }
