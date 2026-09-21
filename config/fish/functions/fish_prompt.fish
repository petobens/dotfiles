function __prompt_transition --argument-names from to
    printf '\e[38;2;%sm\e[48;2;%sm' $from $to
end

function __prompt_text --argument-names text foreground background
    printf '\e[38;2;%sm\e[48;2;%sm%s' $foreground $background $text
end

function __prompt_bold --argument-names text foreground background
    printf '\e[1;38;2;%sm\e[48;2;%sm%s\e[22m' $foreground $background $text
end

function fish_prompt
    set -l command_status $status
    set -l background '36;39;46'
    set -l blue '97;175;239'
    set -l cursor_grey '40;44;52'
    set -l foreground '171;178;191'
    set -l green '152;195;121'
    set -l mono '130;137;151'
    set -l orange '209;154;102'
    set -l purple '198;120;221'
    set -l red '224;108;117'
    set -l special_grey '59;64;72'
    set -l white '208;208;208'

    # Input mode
    set -l mode $fish_bind_mode
    if contains -- --final-rendering $argv
        set mode default
    end

    set -l mode_text I
    set -l mode_color $blue
    switch $mode
        case default operator
            set mode_text N
            set mode_color $green
        case replace replace_one
            set mode_text R
            set mode_color $purple
        case visual
            set mode_text V
    end

    __prompt_bold " $mode_text " $background $mode_color
    __prompt_transition $mode_color $white

    # User and host
    set -l user_color $background
    test "$USER" = root; and set user_color $red
    __prompt_bold " $USER " $user_color $white
    if set -q SSH_CLIENT; or set -q SSH_TTY
        __prompt_bold "󰌘 @"(prompt_hostname)" " $background $white
    end

    set -l band_color $white

    # AWS profile
    if set -q AWS_PROFILE; and test -n "$AWS_PROFILE"
        __prompt_transition $band_color $orange
        __prompt_bold "  $AWS_PROFILE " $background $orange
        set band_color $orange
    end

    # Python virtual environment
    if set -q VIRTUAL_ENV; and test -n "$VIRTUAL_ENV"
        __prompt_transition $band_color $purple
        __prompt_bold "  "(path basename "$VIRTUAL_ENV")" " $background $purple
        set band_color $purple
    end

    # Git repository
    set -l git_lines (command git status --porcelain=v2 --branch --ahead-behind \
        --untracked-files=no 2>/dev/null)
    if test $status -eq 0
        set -l branch
        set -l ahead 0
        set -l behind 0
        set -l modified 0
        for line in $git_lines
            switch $line
                case '# branch.head *'
                    set branch (string replace '# branch.head ' '' -- $line)
                    test "$branch" = '(detached)'; and set branch HEAD
                case '# branch.ab *'
                    set -l divergence (string match -rg '^# branch\.ab \+([0-9]+) -([0-9]+)$' -- $line)
                    set ahead $divergence[1]
                    set behind $divergence[2]
                case '1 *' '2 *'
                    string match -qr '^[12] .M ' -- $line; and set modified (math $modified + 1)
            end
        end

        set -l remote (command git ls-remote --get-url 2>/dev/null)
        set -l remote_icon 
        string match -qi '*github*' -- $remote; and set remote_icon 
        string match -qi '*bitbucket*' -- $remote; and set remote_icon 
        string match -qi '*gitlab*' -- $remote; and set remote_icon 

        __prompt_transition $band_color $special_grey
        __prompt_text " $remote_icon  $branch " $foreground $special_grey
        test $modified -gt 0; and __prompt_text "$modified " $red $special_grey
        test $ahead -gt 0; and __prompt_text "$ahead " $red $special_grey
        test $behind -gt 0; and __prompt_text "$behind " $red $special_grey
        set band_color $special_grey
    end

    # Working directory
    __prompt_transition $band_color $cursor_grey

    set -l path_parts
    if test "$PWD" = "$HOME"
        set path_parts 
    else if string match -q "$HOME/*" -- "$PWD"
        set path_parts  (string split / -- (string replace "$HOME/" '' -- "$PWD"))
    else if test "$PWD" = /
        set path_parts /
    else
        set path_parts / (string split / -- (string replace -r '^/' '' -- "$PWD"))
    end
    if test (count $path_parts) -gt 3
        set path_parts  $path_parts[-3..-1]
    end

    set -l final_part $path_parts[-1]
    set -e path_parts[-1]
    if test (count $path_parts) -gt 0
        __prompt_text ' ' $mono $cursor_grey
        __prompt_text (string join '  ' -- $path_parts)' ' $mono $cursor_grey
    end
    __prompt_bold " $final_part " $mono $cursor_grey

    # Read-only directory and background jobs
    set -l flags
    test -w "$PWD"; or set -a flags 
    set -l job_count (count (jobs -p))
    test $job_count -gt 0; and set -a flags " $job_count"
    if test (count $flags) -gt 0
        __prompt_transition $cursor_grey $orange
        __prompt_bold ' '(string join '  ' -- $flags)' ' $background $orange
        set band_color $orange
    else
        set band_color $cursor_grey
    end

    # Exit status
    if test $command_status -ne 0
        __prompt_transition $band_color $red
        __prompt_bold "  $command_status " $background $red
        printf '\e[38;2;%sm\e[49m' $red
    else
        printf '\e[38;2;%sm\e[49m' $band_color
    end
    printf '\e[0m '
end
