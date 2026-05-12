# ----- guard against non-interactive logins ---------------------------------
[[ -o interactive ]] || return


# Load last directory terminal was open
if [[ -e ~/.last_cd ]]; then
    cd "$(cat ~/.last_cd)"
fi

# ----- convenient alias and function definitions ----------------------------

# color support for ls and grep
alias grep='grep --color=auto'
if [[ $(uname) = "Darwin" || $(uname) = "FreeBSD" ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi

alias killz='killall -9 '
alias hidden='ls -a | grep "^\..*"'
alias rm='rm -v'
alias cp='cp -v'
alias mv='mv -v'
alias shell='ps -p $$ -o comm='


logged_cd() {
    builtin cd "$@"
    pwd > ~/.last_cd
    ls
}
alias cd="logged_cd"

# ----- shell settings and completion ----------------------------------------

export HISTFILE=~/.zsh_history
export HISTSIZE=250000
export SAVEHIST=250000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt APPEND_HISTORY

autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Set 'ls' directory color to be brighter
LS_COLORS=$LS_COLORS:'di=0;94:' ; export LS_COLORS


# ----- change the prompt ----------------------------------------------------

function parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

function parse_hg_branch() {
  hg branch 2> /dev/null | awk '{print " (" $1 ")"}'
}

function set_git_branch() {
  branch=""
  if [[ -x "$(command -v git)" ]]; then
    branch=$(parse_git_branch)
  fi

  # fall back to mercurial only if git found no branch
  if [[ -z "$branch" ]] && [[ -x "$(command -v hg)" ]]; then
    branch=$(parse_hg_branch)
  fi

  if [[ -n "$branch" ]]; then
    BRANCH="%F{magenta}${branch}%f "
  else
    BRANCH=""
  fi
}

function set_virtualenv() {
  if [[ -z "$VIRTUAL_ENV" ]]; then
    PYTHON_VIRTUALENV=""
  else
    PYTHON_VIRTUALENV="%F{cyan}[$(basename "$VIRTUAL_ENV")]%f "
  fi
}

function set_condaenv() {
  if [[ -z "$CONDA_DEFAULT_ENV" ]]; then
    PYTHON_CONDAENV=""
  else
    PYTHON_CONDAENV=" %F{cyan}[$(basename "$CONDA_DEFAULT_ENV")]%f "
  fi
}

precmd() {
    local last_command=$?
    set_virtualenv
    set_condaenv
    set_git_branch

    PROMPT=$'\n'"%K{black}%F{cyan}%D{%a %b %d %Y} :: %f%D{%H:%M:%S}%F{yellow} |-> %~${PYTHON_CONDAENV}${PYTHON_VIRTUALENV}${BRANCH}%f%k"$'\n'
    if [[ $last_command != 0 ]]; then
        PROMPT+="%F{red}%n $ %f"
    else
        PROMPT+="%F{green}%n $ %f"
    fi
}


# ----- utilities ------------------------------------------------------------

function update_dotfiles() {
    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        $HOME/.fzf/install
    fi
    if [[ -d $HOME/.dotfiles ]]; then
        git --git-dir=$HOME/.dotfiles/.git pull origin master
    fi
}

# Find best finder for fzf
SEARCH_BINS=("ag" "rg" "fd")
SEARCH_CMDS=("ag -l --nocolor -g \"\""
"rg --files --follow"
"fd")

for (( idx=1; idx<=${#SEARCH_BINS[@]}; idx++ )); do
    findbin=${SEARCH_BINS[$idx]}
    if [[ $(which $findbin 2> /dev/null) != "" ]]; then
        export FZF_DEFAULT_COMMAND="${SEARCH_CMDS[$idx]}"
        echo "Found alternative to find for fzf: ${FZF_DEFAULT_COMMAND}"
        break
    fi
done

# Ensure git editor uses vim
export GIT_EDITOR="vim -u NONE"
