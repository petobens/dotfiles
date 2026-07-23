#!/usr/bin/env bash
# Claude Code status line: model (effort) | dir | context | rate limits.
# Receives session JSON on stdin (see code.claude.com/docs/en/statusline).

input=$(cat)

# Nerd Font icons (swap the glyphs to taste; terminal needs a patched Nerd Font).
BOT_ICON=$'󰚩' # nf-md-robot
DIR_ICON=$'' # nf-fa-folder_open
CTX_ICON=$'' # nf-fa-window_maximize
RL_ICON=$''  # nf-fa-clock_o

# Model and reasoning effort (effort is absent for models without the param).
# Split on tab only: display_name may contain spaces (e.g. "Opus 4.8 (1M context)").
IFS=$'\t' read -r MODEL EFFORT < <(
	printf '%s' "$input" | jq -r '
        [.model.display_name // "?", (.effort.level // "")] | @tsv'
)
MODEL_SEG="$BOT_ICON $MODEL"
[ -n "$EFFORT" ] && MODEL_SEG="$BOT_ICON $MODEL ($EFFORT)"

# Working directory: last 3 path components, with $HOME abbreviated to ~.
DIR=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""')
DIR="${DIR/#$HOME/\~}"
if [ -n "$DIR" ]; then
	IFS='/' read -ra PARTS <<<"$DIR"
	N=${#PARTS[@]}
	if [ "$N" -gt 3 ]; then
		DIR="…/${PARTS[N - 3]}/${PARTS[N - 2]}/${PARTS[N - 1]}"
	fi
fi

# Context window usage as a percentage (null early in the session -> 0).
PCT=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Rate limits: only present for Pro/Max after the first API response.
IFS=$'\t' read -r RL5 RL7 < <(
	printf '%s' "$input" | jq -r '
        [(.rate_limits.five_hour.used_percentage // ""),
         (.rate_limits.seven_day.used_percentage // "")] | @tsv'
)
RL_SEG=''
[ -n "$RL5" ] && RL_SEG="5h ${RL5%.*}%"
[ -n "$RL7" ] && RL_SEG="${RL_SEG:+$RL_SEG · }7d ${RL7%.*}%"
[ -n "$RL_SEG" ] && RL_SEG="$RL_ICON $RL_SEG"

# Assemble line, joining only the segments that exist with a ' │ ' separator.
SEG=("$MODEL_SEG")
[ -n "$DIR" ] && SEG+=("$DIR_ICON $DIR")
SEG+=("$CTX_ICON ${PCT}%")
[ -n "$RL_SEG" ] && SEG+=("$RL_SEG")
LINE="${SEG[0]}"
for ((i = 1; i < ${#SEG[@]}; i++)); do LINE+=" │ ${SEG[i]}"; done
printf '%s\n' "$LINE"
