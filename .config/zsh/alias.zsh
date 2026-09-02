# vim:ft=zsh

# ══════════════════════════════════════════════════════════════════════════════
# Shell
# ══════════════════════════════════════════════════════════════════════════════

alias ff=fastfetch
alias refreshenv="source $ZDOTDIR/.zshrc"
alias c=clear
alias rf="refreshenv && c"
alias e=$EDITOR
# edit root-owned files as yourself; sudoedit writes the result back as root
# (running nvim under sudo leaves root-owned files in ~/.local/share/nvim)
alias svim='sudoedit'

# ══════════════════════════════════════════════════════════════════════════════
# Listing (eza)
# ══════════════════════════════════════════════════════════════════════════════

alias eza="eza --group-directories-first --color=always --icons=always"
alias l="eza --oneline"
alias ls="eza --grid"
alias la="l --all"
alias ll="la --long --git -g"
alias lf="ll --only-files"
alias ld="ll --only-dirs"
alias lr="ll --sort=new --color-scale=age --color-scale-mode=gradient"
alias lx="lf --sort=extension"
alias lb="lf --sort=size --reverse --color-scale=size --color-scale-mode=gradient"
alias lt="eza --tree --all"

# ══════════════════════════════════════════════════════════════════════════════
# File Operations
# ══════════════════════════════════════════════════════════════════════════════

alias grep="grep --color=always"
alias cp="cp -ri"
alias mv="mv -i"
alias sync="rsync -avzuPh --delete"
alias rm="trash --trash-dir $XDG_TRASH_DIR"
alias wget="wget --continue --progress=bar --timestamping"


# ══════════════════════════════════════════════════════════════════════════════
# Systemd
# ══════════════════════════════════════════════════════════════════════════════

alias sa=systemd-analyze


# ══════════════════════════════════════════════════════════════════════════════
# Journalctl
# ══════════════════════════════════════════════════════════════════════════════

alias jl="journalctl -b -p 0..5"
alias jf="journalctl -b | rg '(fail|error|warn|[^(de)]bug)'"


# ══════════════════════════════════════════════════════════════════════════════
# Paru/Pacman
# ══════════════════════════════════════════════════════════════════════════════

alias pup="paru -Syyu"
pun() { paru -Rns "$@"; }

# ══════════════════════════════════════════════════════════════════════════════
# Resources
# ══════════════════════════════════════════════════════════════════════════════

alias df="df -h"
alias du="du -h"
alias nvtop="nvtop -E -1"


# ══════════════════════════════════════════════════════════════════════════════
# Git
# ══════════════════════════════════════════════════════════════════════════════

alias gad='git add'
alias gst='git status'
alias gl='git pull'
alias gp='git push'
alias gc='git commit -v'
alias glog="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'"


# ══════════════════════════════════════════════════════════════════════════════
# Dotfiles
# ══════════════════════════════════════════════════════════════════════════════

alias dotfiles=dotbare
alias config=dotfiles
alias todo-git='git --git-dir="$HOME/.todo.git" --work-tree="$HOME"'  # local-only TODO.md/DONE.md history
alias ts=theme
alias theme-switcher=theme  # backwards compatibility
alias wp=wallpaper

# ══════════════════════════════════════════════════════════════════════════════
# Help
# ══════════════════════════════════════════════════════════════════════════════

alias -g -- --help="--help 2>&1 | bat --language=help --style=plain"

# ══════════════════════════════════════════════════════════════════════════════
# Fun
# ══════════════════════════════════════════════════════════════════════════════

alias ascii='find ~/.local/bin/ascii -maxdepth 1 -type f | fzf --preview="sh {}" \
  --bind="enter:execute(sh {})+abort"'
alias colorscripts='find ~/.local/bin/ascii/color-scripts -type f | fzf --preview="sh {}" \
  --bind="enter:execute(sh {})+abort"'
alias rascii='find ~/.local/bin/ascii -maxdepth 1 -type f | shuf -n 1 | sh'
alias rcolorscripts='find ~/.local/bin/ascii/color-scripts -type f | shuf -n 1 | sh'

# ══════════════════════════════════════════════════════════════════════════════
# Phone (MTP)
# ══════════════════════════════════════════════════════════════════════════════

alias phone='systemctl --user start phone-mount.service'      # mount   -> ~/phone
alias phone-off='systemctl --user stop phone-mount.service'   # unmount ~/phone
