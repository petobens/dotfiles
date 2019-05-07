runtime! syntax/sql.vim
unlet b:current_syntax

syntax include @jinja syntax/jinja.vim
syntax region jinjaSyntax start=/{[{#\%\[]/ skip="(\/\*|\*\/|--)" end=/[}#\%\]]}/ contains=@jinja

let b:current_syntax='jinja_sql'
