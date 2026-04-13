# Zsh configuration file
export SHELL=/usr/bin/zsh

# Recover automatically when shell starts from a deleted directory.
if [[ -z "${PWD:-}" || ! -d "$PWD" ]]; then
  cd "$HOME" || return 1
fi

# Increase FUNCNEST to prevent "maximum nested function level reached" errors
# This is needed for Oh My Posh + zsh-autosuggestions/zsh-syntax-highlighting
export FUNCNEST=1000

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Disable theme to use Oh My Posh instead
ZSH_THEME=""

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PIPENV_PYTHON="$PYENV_ROOT/shims/python"

plugins=(
  pyenv
  git
  npm
  sudo
)

# Custom plugins
plugins+=(zsh-autosuggestions zsh-syntax-highlighting)

[ -f ~/.zshrc-local ] && source ~/.zshrc-local

source $ZSH/oh-my-zsh.sh
source ~/.nvm/nvm.sh

# Disable share history across consoles
unsetopt share_history

# Aliases - Remove what you don't need
alias gs="git status -sb"
alias zshreload="source $HOME/.zshrc"
alias zshconfig="mate $HOME/.zshrc"
alias ohmyzsh="mate $HOME/.oh-my-zsh"
alias diskspace="sudo du -shx * | sort -rh | head -10"

# Specific aliases for RotorHazard
alias rh_restart="sudo systemctl restart rotorhazard"
alias rh_status="sudo systemctl status rotorhazard"

# Venv
alias venv_enter="source .venv/bin/activate"
alias venv_create="python3 -m venv .venv"

# Pip
alias pip_freeze="pip freeze > requirements.txt"
alias pip_install="pip install -r requirements.txt"

# Uv
alias uv_install="uv pip install -r requirements.txt"
alias uv_venv="uv venv"
alias uvdate="uv self update"

# Pyenv
alias pyenv_list='pyenv install --list | grep -E "^\s*3\.(11|12|13|14)(\..*|-dev.*)"'

# Git
git_rm_branches() {
  local branches=$(git branch | grep "$1")

  if [ -z "$branches" ]; then
    echo "No branches found matching pattern '$1'."
    return 1
  fi

  echo "Branches found matching pattern '$1':"
  echo "$branches"

  read -r "REPLY?Do you want to delete these branches? (y/n): "
  case "$REPLY" in
    [Yy])
      echo "$branches" | xargs git branch -D
      echo "Branches deleted successfully."
      ;;
    *)
      echo "Operation cancelled."
      ;;
  esac
}

# fzf
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh

# Automatically check venv and node modules for executables
export PATH="./venv/bin:./node_modules/.bin:~/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Pyenv
eval "$(pyenv init -)"
eval "$(command pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Uv
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

eval "$(uv generate-shell-completion zsh)"

# Oh My Posh with custom theme - MUST be loaded LAST after all other plugins
eval "$(oh-my-posh init zsh --config ~/.theme.omp.json)"
