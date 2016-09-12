"===============================================================================
"          File: matlab.vim
"        Author: Pedro Ferrari
"       Created: 03 Oct 2015
" Last Modified: 03 Oct 2015
"   Description: Matlab indent file
"===============================================================================
" Original Maintainer:	Fabrice Guy <fabrice.guy at gmail dot com>

" Only load this indent file when no other was loaded.
if exists('b:did_indent')
  finish
endif
let b:did_indent = 1
let s:functionWithoutEndStatement = 0

setlocal indentexpr=GetMatlabIndent()
setlocal indentkeys=!,o,O=end,=case,=else,=elseif,=otherwise,=catch

" Only define the function once.
if exists('*GetMatlabIndent')
  finish
endif

function! s:IsMatlabContinuationLine(lnum)
  let continuationLine = 0
  if a:lnum > 0
    let pnbline = getline(prevnonblank(a:lnum))
    " if we have the line continuation operator (... at the end of a line or
    " ... followed by a comment) it may be a line continuation
    if pnbline =~# '\.\.\.\s*$' || pnbline =~# '\.\.\.\s*%.*$'
      let continuationLine = 1
      " but if the ... are part of a string or a comment, it is not a
      " continuation line
      let col = match(pnbline, '\.\.\.\s*$')
      if col == -1
        let col = match(pnbline, '\.\.\.\s*%.*$')
      endif
      if has('syntax_items')
        if synIDattr(synID(prevnonblank(a:lnum), col + 1, 1), 'name') =~#
                    \ 'matlabString' || synIDattr(synID(prevnonblank(a:lnum),
                    \ col + 1, 1), 'name') =~# 'matlabComment'
          let continuationLine = 0
        endif
      endif
    endif
  endif
  return continuationLine
endfunction

function GetMatlabIndent()
  " Find a non-blank line above the current line.
  let plnum = prevnonblank(v:lnum - 1)

  " If the previous line is a continuation line, get the beginning of the block
  " to use the indent of that line
  if s:IsMatlabContinuationLine(plnum - 1)
    while s:IsMatlabContinuationLine(plnum - 1)
      let plnum = plnum - 1
    endwhile
  endif

  " At the start of the file use zero indent.
  if plnum == 0
    return 0
  endif

  let curind = indent(plnum)
  if s:IsMatlabContinuationLine(v:lnum - 1)
    let curind = curind + &sw
  endif
  " Add a 'shiftwidth' after classdef, properties, switch, methods, events,
  " function, if, while, for, otherwise, case, try, catch, else, elseif
  if getline(plnum) =~# '^\s*\(classdef\|properties\|switch\|methods\|' .
              \ 'events\|function\|if\|while\|for\|otherwise\|case\|try\|' .
              \ 'catch\|else\|elseif\)\>'
    let curind = curind + &sw
    " In Matlab we have different kind of functions
    " - the main function (the function with the same name than the filename)
    " - the nested functions
    " - the functions defined in methods (for classes)
    " - subfunctions
    " Principles for the indentation :
    " - all the function keywords are indented (corresponding to the
    "   'indent all functions' in the Matlab Editor)
    " - if we have only subfonctions (ie if the main function doesn't have
    "   any mayching end), then each function is dedented
    if getline(plnum)  =~# '^\s*\function\>'
      let pplnum = plnum - 1
      while pplnum > 1 && (getline(pplnum) =~# '^\s*%')
        let pplnum = pplnum - 1
      endwhile
      " If it is the main function, determine if function has a matching end
      " or not
      if pplnum <= 1
        " look for a matching end :
        " - if we find a matching end everything is fine : end of functions
        "   will be dedented when 'end' is reached
        " - if not, then all other functions are subfunctions : 'function'
        "   keyword has to be dedended
        let old_lnum = v:lnum
        let motion = plnum . 'gg'
        execute 'normal' . motion
        normal %
        if getline(line('.')) =~# '^\s*end'
          let s:functionWithoutEndStatement = 0
        else
          let s:functionWithoutEndStatement = 1
        endif
        normal %
        let motion = old_lnum . 'gg'
        execute 'normal' . motion
      endif
    endif
    " if the for-end block (or while-end) is on the same line : dedent
    if getline(plnum)  =~# '\<end[,;]*\s*\(%.*\)\?$'
      let curind = curind - &sw
    endif
  endif

  " Subtract a 'shiftwidth' on a else, elseif, end, catch, otherwise, case
  if getline(v:lnum) =~# '^\s*\(else\|elseif\|end\|catch\|otherwise\|case\)\>'
    let curind = curind - &sw
  endif
  " No indentation in a subfunction
  if getline(v:lnum)  =~# '^\s*\function\>' && s:functionWithoutEndStatement
    let curind = curind - &sw
  endif
  " First case after a switch : indent
  if getline(v:lnum) =~# '^\s*case'
    while plnum > 0 && (getline(plnum) =~# '^\s*%' ||
                \ getline(plnum) =~# '^\s*$')
      let plnum = plnum - 1
    endwhile
    if getline(plnum) =~# '^\s*switch'
      let curind = indent(plnum) + &sw
    endif
  endif

  " end in a switch / end block : dedent twice
  " we use the matchit script to know if this end is the end of a switch block
  if exists('b:match_words')
    if getline(v:lnum) =~# '^\s*end'
      normal %
      if getline(line('.')) =~# '^\s*switch'
        let curind = curind - &sw
      endif
      normal %
    end
  end
  return curind
endfunction

" vim:sw=2
