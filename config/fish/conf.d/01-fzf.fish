set -gx FZF_DEFAULT_OPTS '
--border=bottom
--border-label-pos=50
--height=15
--info=inline
--prompt="   "
--pointer=">"
--marker=" "
--no-separator
--preview-window=border-left
--bind=ctrl-space:toggle+up,ctrl-d:half-page-down,ctrl-u:half-page-up
--bind=alt-v:toggle-preview,alt-j:preview-down,alt-k:preview-up
--bind=alt-d:preview-half-page-down,alt-u:preview-half-page-up
--color=bg+:#282c34,bg:#24272e,fg:#abb2bf,fg+:#abb2bf,hl:#528bff,hl+:#528bff
--color=prompt:#c678dd,header:#566370,info:#5c6370,pointer:#c678dd
--color=marker:#d19a66,spinner:#e06c75,border:#282c34,label:#566370
'
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git --color=always --strip-cwd-prefix'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git --strip-cwd-prefix'
set -gx FZF_CTRL_R_OPTS '
--border-label="Command History"
--bind="ctrl-y:execute-silent(printf %s {3..} | wl-copy)+abort,tab:accept"
--header="enter=insert, tab=insert, C-y=yank"
'
