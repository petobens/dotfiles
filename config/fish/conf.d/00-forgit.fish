set -gx FORGIT_COPY_CMD wl-copy
set -gx FORGIT_NO_ALIASES 1
set -gx FORGIT_FZF_DEFAULT_OPTS '--preview-window=right'
set -gx FORGIT_LOG_FZF_OPTS '
--header="enter=view, C-o=nvim, C-y=yank"
--bind="ctrl-y:execute-silent(echo {} | grep -Eo [a-f0-9]+ | head -1 | wl-copy)"
--bind="ctrl-o:execute(echo {} | grep -Eo [a-f0-9]+ | head -1 | xargs git show | nvim -)"
'
