# Path
export ZSH="$HOME/.oh-my-zsh"
export PATH=$PATH:/home/(name)/.fzf/bin
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export EDITOR="nvim"
export VISUAL="nvim"
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

PATH="/Users/notori/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/Users/notori/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/Users/notori/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/Users/notori/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/Users/notori/perl5"; export PERL_MM_OPT;
