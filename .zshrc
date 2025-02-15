# Path
export ZSH="$HOME/.oh-my-zsh"
export PATH=$PATH:/home/(name)/.fzf/bin
# export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin/nvim

# Theme
ZSH_THEME="robbyrussell"

# Update setting
zstyle ':omz:update' mode reminder  # just remind me to update when it's time
zstyle ':omz:update' frequency 13

# plugins
plugins=(
  git
  fzf
  history-substring-search
  colored-man-pages
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# alias
alias r="sh ./run.sh"

# init
source $ZSH/oh-my-zsh.sh

# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
