export ZSH="/home/nschieder/.oh-my-zsh"
ZSH_THEME="agnoster"
DISABLE_AUTO_UPDATE="true"


plugins=(git zsh-autosuggestions zsh-completions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
