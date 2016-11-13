# BlackRain ZSH Theme
# Author: Ed Heltzel @ginfuru
# License: MIT

__PROMPT_SYMBOL="❯"
__UNCOMMITTED="+"
__UNSTAGED="!"
__UNTRACKED="?"
__STASHED="$"
__UNPULLED="⇣"
__UNPUSHED="⇡"
__NVM_SYMBOL="⬢"

# Username.
# If user is root, then pain it in red. Otherwise, just print in yellow.
__user() {
  if [[ $USER == 'root' ]]; then
    echo -n "%{$fg_bold[red]%}"
  else
    echo -n "%{$fg_bold[yellow]%}"
  fi
  echo -n "%n"
  echo -n "%{$reset_color%}"
}

# Username and SSH host
# If there is an ssh connections, then show user and current machine.
# If user is not $USER, then show username.
__host() {
  if [[ -n $SSH_CONNECTION ]]; then
    echo -n "$(__user)"
    echo -n " %Bat%b "
    echo -n "%{$fg_bold[green]%}%m%{$reset_color%}"
    echo -n " %Bin%b "
  elif [[ $LOGNAME != $USER ]] || [[ $USER == 'root' ]]; then
    echo -n "$(__user)"
    echo -n " %Bin%b "
    echo -n "%{$reset_color%}"
  fi
}

# Current directory.
# Return only the last 2 items of path
__current_dir() {
  echo -n "%{$fg_bold[cyan]%}"
  echo -n "%2~"
  echo    "%{$reset_color%}"
}

# Uncommitted changes.
# Check for uncommitted changes in the index.
__git_uncomitted() {
  if ! $(git diff --quiet --ignore-submodules --cached); then
    echo -n "%{$fg_bold[green]%}+%{$fg[red]%}"
  fi
}

# Unstaged changes.
# Check for unstaged changes.
__git_unstaged() {
  if ! $(git diff-files --quiet --ignore-submodules --); then
    echo -n '!'
  fi
}

# Untracked files.
# Check for untracked files.
__git_untracked() {
  if [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo -n "%{$fg_bold[white]%}?%{$fg[red]%}"
  fi
}

# Stashed changes.
# Check for stashed changes.
__git_stashed() {
  if $(git rev-parse --verify refs/stash &>/dev/null); then
    echo -n "%{$fg_bold[magenta]%}$%{$fg[red]%}"
  fi
}

# Unpushed and unpulled commits.
# Get unpushed and unpulled commits from remote and draw arrows.
__git_unpushed_unpulled() {
  # check if there is an upstream configured for this branch
  command git rev-parse --abbrev-ref @'{u}' &>/dev/null || return

  local count
  count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"
  # exit if the command failed
  (( !$? )) || return

  # counters are tab-separated, split on tab and store as array
  count=(${(ps:\t:)count})
  local arrows left=${count[1]} right=${count[2]}

  (( ${right:-0} > 0 )) && arrows+="%{$fg[cyan]%}${__UNPULLED}%{$fg[red]%}"
  (( ${left:-0} > 0 )) && arrows+="%{$fg[cyan]%}${__UNPUSHED}%{$fg[red]%}"

  [ -n $arrows ] && echo -n "${arrows}"
}

# Git status.
# Collect indicators, git branch and pring string.
__git_status() {
  # Check if the current directory is in a Git repository.
  command git rev-parse --is-inside-work-tree &>/dev/null || return

  # Check if the current directory is in .git before running git checks.
  if [[ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]]; then
    # Ensure the index is up to date.
    git update-index --really-refresh -q &>/dev/null

    # String of indicators
    local s=''

    s+="$(__git_uncomitted)"
    s+="$(__git_unstaged)"
    s+="$(__git_untracked)"
    s+="$(__git_stashed)"
    s+="$(__git_unpushed_unpulled)"

    [ -n "${s}" ] && s=" [${s}]";

    echo -n " %Bon%b "
    echo -n "%{$FG[239]%}\ue0a0 "
    echo -n "%{$reset_color%}"
    echo -n "%{$fg_bold[magenta]%}"
    echo -n "$(git_current_branch)"
    echo -n "%{$reset_color%}"
    echo -n "%{$fg_bold[red]%}"
    echo -n "${s}"
    echo -n "%{$reset_color%}"
  fi
}

# Virtual environment.
# Show current virtual environment (Python).
__venv_status() {
  # Check if the current directory running via Virtualenv
  [ -n "$VIRTUAL_ENV" ] || return
  echo -n " %Bvia%b "
  echo -n "%{$fg_bold[blue]%}"
  echo -n "$(basename $VIRTUAL_ENV)"
  echo -n "%{$reset_color%}"
}

# NVM
# Show current version of node, exception system.
__nvm_status() {
  $(type nvm >/dev/null 2>&1) || return

  local nvm_status=$(nvm current 2>/dev/null)
  [[ "${nvm_status}" == "system" ]] && return
  nvm_status=${nvm_status}

  echo -n " %Bvia%b "
  echo -n "%{$fg_bold[green]%}"
  echo -n "${__NVM_SYMBOL} ${nvm_status}"
  echo -n "%{$reset_color%}"
}

# Command prompt.
# Pain $PROMPT_SYMBOL in red if previous command was fail and
# pain in green if all OK.
__return_status() {
  echo -n "%(?.%{$fg[green]%}.%{$fg[red]%})"
  echo -n "%B${__PROMPT_SYMBOL}%b"
  echo    "%{$reset_color%}"
}

# Compose PROMPT
PROMPT='
$(__host)$(__current_dir)$(__git_status)$(__nvm_status)$(__venv_status)
$(__return_status) '

# Set PS2 - continuation interactive prompt
PS2="%{$fg_bold[yellow]%}"
PS2+="${__PROMPT_SYMBOL} "
PS2+="%{$reset_color%}"

# Customize to your needs...
#RPROMPT='%{$fg[white]%}$(battery_pct_prompt)%{$reset_color%}' #add battery to plugins to get this to work
