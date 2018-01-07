" TODO: Improve line number alignment <29/08/2013 16:57:13> "
" TODO: Use vimtex manual folding refresh?

" Initialization {{{

if exists('b:loaded_mylatexfolding')
    finish
endif
let b:loaded_mylatexfolding = 1

" }}}
" Set options {{{

setlocal foldmethod=expr
setlocal foldexpr=MyLatexFold_FoldLevel(v:lnum)
setlocal foldtext=MyLatexFold_FoldText()

if !exists('g:MyLatexFold_fold_preamble')
    let g:MyLatexFold_fold_preamble = 1
endif

if !exists('g:MyLatexFold_fold_parts')
    let g:MyLatexFold_fold_parts = [
                \ 'appendix',
                \ 'frontmatter',
                \ 'mainmatter',
                \ 'backmatter'
                \ ]
endif

if !exists('g:MyLatexFold_fold_sections')
    let g:MyLatexFold_fold_sections = [
                \ 'part',
                \ 'chapter',
                \ 'section',
                \ 'subsection',
                \ 'subsubsection'
                \ ]
endif

if !exists('g:MyLatexFold_fold_envs')
    let g:MyLatexFold_fold_envs = 1
endif
if !exists('g:MyLatexFold_folded_environments')
    let g:MyLatexFold_folded_environments = [
                \ 'abstract',
                \ 'frame'
                \ ]
endif

" }}}
" MyLatexFold_FoldLevel helper functions {{{

" This function parses the tex file to find the sections that are to be folded
" and their levels, and then predefines the patterns for optimized folding.
function! s:FoldSectionLevels()
    " Initialize
    let level = 1
    let foldsections = []

    " If we use two or more of the *matter commands, we need one more foldlevel
    let nparts = 0
    for part in g:MyLatexFold_fold_parts
        let i = 1
        while i < line('$')
            if getline(i) =~ '^\s*\\' . part . '\>'
                let nparts += 1
                break
            endif
            let i += 1
        endwhile
        if nparts > 1
            let level = 2
            break
        endif
    endfor

    " Combine sections and levels, but ignore unused section commands:  If we
    " don't use the part command, then chapter should have the highest
    " level.  If we don't use the chapter command, then section should be the
    " highest level.  And so on.
    let ignore = 1
    for part in g:MyLatexFold_fold_sections
        " For each part, check if it is used in the file.  We start adding the
        " part patterns to the fold sections array whenever we find one.
        let partpattern = '^\s*\(\\\|% Fake\)' . part . '\>'
        if ignore
            let i = 1
            while i < line('$')
                if getline(i) =~# partpattern
                    call insert(foldsections, [partpattern, level])
                    let level += 1
                    let ignore = 0
                    break
                endif
                let i += 1
            endwhile
        else
            call insert(foldsections, [partpattern, level])
            let level += 1
        endif
    endfor

    return foldsections
endfunction

" }}}
" MyLatexFold_FoldLevel {{{

" Parse file to dynamically set the sectioning fold levels
let b:MyLatexFold_FoldSections = s:FoldSectionLevels()

" Optimize by predefine common patterns
let s:foldparts = '^\s*\\\%(' . join(g:MyLatexFold_fold_parts, '\|') . '\)'
let s:folded = '\(% Fake\|\\\(document\|begin\|end\|'
            \ . 'front\|main\|back\|app\|sub\|section\|chapter\|part\)\)'

" Fold certain selected environments
let s:notbslash = '\%(\\\@<!\%(\\\\\)*\)\@<='
let s:notcomment = '\%(\%(\\\@<!\%(\\\\\)*\)\@<=%.*\)\@<!'
let s:envbeginpattern = s:notcomment . s:notbslash .
            \ '\\begin\s*{\('. join(g:MyLatexFold_folded_environments, '\|') .'\)}'
let s:envendpattern = s:notcomment . s:notbslash .
            \ '\\end\s*{\('. join(g:MyLatexFold_folded_environments, '\|') . '\)}'

function! MyLatexFold_FoldLevel(lnum)
    " Check for normal lines first (optimization)
    let line  = getline(a:lnum)
    if line !~ s:folded
        return '='
    endif

    " Fold preamble
    if g:MyLatexFold_fold_preamble == 1
        if line =~# s:notcomment . s:notbslash . '\s*\\documentclass'
            return '>1'
        elseif line =~# s:notcomment . s:notbslash .
                    \ '\s*\\begin\s*{\s*document\s*}'
            return '0'
        endif
    endif

    " Fold parts (\frontmatter, \mainmatter, \backmatter, and \appendix)
    if line =~# s:foldparts
        return '>1'
    endif

    " Fold chapters and sections
    for [part, level] in b:MyLatexFold_FoldSections
        if line =~# part
            return '>' . level
        endif
    endfor

    " Never fold \end{document}
    if line =~# '^\s*\\end{document}'
        return 0
    endif

    " Fold environments
    if g:MyLatexFold_fold_envs == 1
        if line =~# s:envbeginpattern
            return 'a1'
        elseif line =~# s:envendpattern
            return 's1'
        endif
    endif

    " Return foldlevel of previous line
    return '='
endfunction

" }}}
" MyLatexFold_FoldText helper functions {{{

function! s:CaptionFrame(line)
    " Test simple variants first
    let caption1 = matchstr(a:line,'\\begin\*\?{.*}{\zs.\+\ze}')
    let caption2 = matchstr(a:line,'\\begin\*\?{.*}{\zs.\+')

    if len(caption1) > 0
        return caption1
    elseif len(caption2) > 0
        return caption2
    else
        let i = v:foldstart
        while i <= v:foldend
            if getline(i) =~# '^\s*\\frametitle'
                return matchstr(getline(i),
                            \ '^\s*\\frametitle\(\[.*\]\)\?{\zs.\+')
            end
            let i += 1
        endwhile

        return ''
    endif
endfunction

" }}}
" MyLatexFold_FoldText {{{

function! MyLatexFold_FoldText()
    " Initialize
    let line = getline(v:foldstart)
    let nlines = v:foldend - v:foldstart + 1
    let level = ''
    let title = 'Not defined'

    " Fold level and number of lines
	let level = '+-' . repeat('-', v:foldlevel-1) . ' '
    let alignlnr = repeat(' ', 6-(v:foldlevel-1)-len(nlines))
    let lineinfo = nlines . ' lines: '

    " Preamble
    if line =~# '\s*\\documentclass'
        let title = 'Preamble'
    endif

    " Parts, sections and fakesections
    let sections = '\(\(sub\)*section\|part\|chapter\)'
    let secpat1 = '^\s*\\' . sections . '\*\?\s*{'
    let secpat2 = '^\s*\\' . sections . '\*\?\s*\['
    if line =~# '\\frontmatter'
        let title = 'Frontmatter'
    elseif line =~# '\\mainmatter'
        let title = 'Mainmatter'
    elseif line =~# '\\backmatter'
        let title = 'Backmatter'
    elseif line =~# '\\appendix'
        let title = 'Appendix'
    elseif line =~ secpat1 . '.*}'
        let title =  line
    elseif line =~ secpat1
        let title = line
    elseif line =~ secpat2 . '.*\]'
        let title = line
    elseif line =~ secpat2
        let title = line
    elseif line =~ 'Fake' . sections . ':'
        let title =  matchstr(line,'Fake' . sections . ':\s*\zs.*')
    elseif line =~ 'Fake' . sections
        let title =  matchstr(line, 'Fake' . sections)
    endif

    " Environments
    if line =~# '\\begin'
        " Capture environment name
        let env = matchstr(line,'\\begin\*\?{\zs\w*\*\?\ze}')
        if env ==# 'abstract'
            let title = 'Abstract'
        elseif env ==# 'frame'
            let caption = s:CaptionFrame(line)
            let title = 'Frame - ' . substitute(caption, '}\s*$', '','')
        endif
    endif

    return level . alignlnr . lineinfo . title . ' '
endfunction

" }}}
