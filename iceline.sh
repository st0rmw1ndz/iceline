#!/bin/bash

case "$-" in
*i*) ;;
*) return ;;
esac

# Time color
PROMPT_COL_TIME='\[\e[0;37m\]'
# user@host color
PROMPT_COL_USER_HOST='\[\e[1;32m\]'
# root user color
PROMPT_COL_ROOT='\[\e[1;31m\]'
# Working directory color
PROMPT_COL_WORK_DIR='\[\e[1;34m\]'
# Clean git branch color
PROMPT_COL_GIT_CLEAN='\[\e[1;35m\]'
# Dirty git branch color
PROMPT_COL_GIT_DIRTY='\[\e[1;33m\]'
# Success exit code color
PROMPT_COL_SUCCESS='\[\e[1;32m\]'
# Failure exit code color
PROMPT_COL_FAILURE='\[\e[1;31m\]'
# Line color
PROMPT_COL_LINE='\[\e[0;37m\]'
# SSH notice color
PROMPT_COL_SSH='\[\e[1;32m\]'
# Time format
PROMPT_TIME_FORMAT='%H:%M:%S'
# Prompt character
PROMPT_CHARACTER='>'
# Initial newline
PROMPT_ENABLE_NEWLINE=1
# Line toggle
PROMPT_ENABLE_LINE=1
# Window title
PROMPT_ENABLE_TITLE=1
# Git information
PROMPT_ENABLE_GIT=1

_is_git_capable() {
    # Determines if git is available.

    command -v git >/dev/null
}

_is_title_capable() {
    # Determines if the terminal is window title capable.

    case "$TERM" in
    linux) return 1 ;;
    *) return 0 ;;
    esac
}

_set_window_title() {
    # Sets the shell window title.

    printf '\033]0;%s\007' "$1"
}

_parse_git_branch() {
    # Queries the branch of the current Git repository.

    if ! git_branch="$(git branch 2>/dev/null)" || [ -z "$git_branch" ]; then
        return 1
    fi

    git_branch="${git_branch#* }"

    printf '%s' "$git_branch"
}

_parse_git_changes() {
    # Queries whether there's changes in the current Git repository.

    if ! git_status="$(git status --porcelain 2>/dev/null)"; then
        return 1
    fi

    if [ -z "$git_status" ]; then
        printf '%s' "$PROMPT_COL_GIT_CLEAN"
    else
        printf '%s' "$PROMPT_COL_GIT_DIRTY"
    fi
}

_prompt_command() {
    # Last exit code
    _last_exit="$?"

    # Exit code color
    case "$_last_exit" in
    0 | 130) _prompt_color="$PROMPT_COL_SUCCESS" ;;
    *) _prompt_color="$PROMPT_COL_FAILURE" ;;
    esac

    # Reset prompt
    PS1="\[\e[0;0m\]"

    # First newline
    [ -n "$PROMPT_ENABLE_NEWLINE" ] && PS1+="\n"

    # Top part of line
    [ -n "$PROMPT_ENABLE_LINE" ] && PS1+="${PROMPT_COL_LINE}┌ "

    # Date
    PS1+="${PROMPT_COL_TIME}\D{${PROMPT_TIME_FORMAT}} "

    # user@host OR root
    if [ "$EUID" -ne 0 ]; then
        PS1+="${PROMPT_COL_USER_HOST}\u@\h "
    else
        PS1+="${PROMPT_COL_ROOT}\u "
    fi

    # Working directory
    PS1+="${PROMPT_COL_WORK_DIR}\w "

    # Git information (if applicable)
    _is_git_capable && [ -n "$PROMPT_ENABLE_GIT" ] && _git_branch="$(_parse_git_branch)" && _git_status="$(_parse_git_changes)" && PS1+="${_git_status}(${_git_branch}) "

    # Newline
    PS1+="\n"

    # Bottom part of line
    [ -n "$PROMPT_ENABLE_LINE" ] && PS1+="${PROMPT_COL_LINE}└ "

    # SSH information (if applicable)
    [ -n "$SSH_CLIENT" ] && PS1+="${PROMPT_COL_SSH}SSH "

    # Prompt character
    PS1+="${_prompt_color}${PROMPT_CHARACTER} "

    # Ending reset
    PS1+="\[\e[0;0m\]"

    # Window title
    if _is_title_capable && [ -n "$PROMPT_ENABLE_TITLE" ]; then
        case "$PWD" in
        /home/"$USER"*) _cwd="~${PWD#/home/"$USER"}" ;;
        *) _cwd="$PWD" ;;
        esac
        _set_window_title "$(printf '%s@%s - %s' "$USER" "$HOSTNAME" "$_cwd")"
    fi
}
