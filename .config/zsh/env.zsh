# vim:ft=zsh

# ══════════════════════════════════════════════════════════════════════════════
# Defaults
# ══════════════════════════════════════════════════════════════════════════════

export FUNCNEST=100
export TERMINAL=kitty
export BROWSER=firefox
export VISUAL=nvim
export EDITOR=nvim
export SUDO_EDITOR=nvim
export LESS="-Ss~ --ignore-case --LONG-PROMPT --quit-if-one-screen --RAW-CONTROL-CHARS --use-color"

# ══════════════════════════════════════════════════════════════════════════════
# XDG Path Corrections
# ══════════════════════════════════════════════════════════════════════════════

# Trash (used by trash-cli rm alias)
export XDG_TRASH_DIR="$XDG_DATA_HOME/Trash"

# Bat (theme managed by ~/.config/bat/config via theme-switcher)
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# Bookmarks
export BOOKMARKS_FILE="$XDG_DATA_HOME/bookmarks"

# Buku
export BUKU_COLORS='hEhhf'

# Bun
export BUN_INSTALL="$XDG_DATA_HOME/bun"

# Cuda
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# Dotbare
export DOTBARE_DIR="$HOME/.dotfiles"
export DOTBARE_TREE="$HOME"

# GDB
export GDBHISTFILE="$XDG_DATA_HOME/gdb/history"

# GnuPG
export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"
export GPG_TTY=$(tty)

# Go
export GOPATH="$XDG_DATA_HOME/go"
export GOCACHE="$XDG_CACHE_HOME/go-build"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"

# Gradle
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"

# GTK
export GTK_RC_FILES="$XDG_CONFIG_HOME/gtk-1.0/gtkrc"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc:$XDG_CONFIG_HOME/gtk-2.0/gtkrc.mine"

# Java
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java

# Lazygit (theme managed by symlink via theme-switcher)
export LG_CONFIG_FILE="$XDG_CONFIG_HOME/lazygit/config.yml"

# Lynx
export LYNX_CFG="$XDG_CONFIG_HOME/lynx.cfg"

# NNN
export NNN_FIFO='/tmp/nnn.fifo'
export NNN_TRASH=1
export NNN_COLORS='4652'
export NNN_FCOLORS='0203040a000d0608090b0501'
export NNN_PLUG='p:preview-tui;o:launch'
export NNN_OPTS='deEPrUx'

# Nodejs
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NVM_DIR="$XDG_DATA_HOME/nvm"

# Parallel
export PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"

# Postgresql
export PSQLRC="$XDG_CONFIG_HOME/pg/psqlrc"
export PSQL_HISTORY="$XDG_STATE_HOME/psql_history"
export PGPASSFILE="$XDG_CONFIG_HOME/pg/pgpass"
export PGSERVICEFILE="$XDG_CONFIG_HOME/pg/pg_service.conf"

# Python
export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME/python"
export PYTHONUSERBASE="$XDG_DATA_HOME/python"

# Ruby
export GEM_HOME=$(gem env user_gemhome)

# Rust
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

# Starship
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export STARSHIP_CACHE="$XDG_CACHE_HOME/starship"

# Wget
export WGETRC="$XDG_CONFIG_HOME/wgetrc"

# Android SDK
export ANDROID_HOME="$XDG_DATA_HOME/android-sdk"

# Zoxide
export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
export _ZO_FZF_OPTS="+m"
#export _ZO_EXCLUDE_DIRS="$HOME/.cache:$HOME/.local"

# Eza (uncomment to customize)
#export EZA_COLORS='da=1;34:gm=1;34:Su=1;34'

# ══════════════════════════════════════════════════════════════════════════════
# Plugin Configuration
# ══════════════════════════════════════════════════════════════════════════════

# ZSH history substring search
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
HISTORY_SUBSTRING_SEARCH_FUZZY=1

# ZSH Autosuggestion (highlight style set in theme's shell-colors.sh)
typeset -ga ZSH_AUTOSUGGEST_STRATEGY
ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30

# ══════════════════════════════════════════════════════════════════════════════
# Path & Initialization
# ══════════════════════════════════════════════════════════════════════════════

# Zoxide
eval "$(zoxide init zsh --cmd cd)"

# GoWall (uncomment if using)
#source <(gowall completion zsh)

# Path (typeset -U removes duplicates)
typeset -U path PATH
path=(
  "$XDG_SCRIPT_HOME"
  "$BUN_INSTALL/bin"
  "$GEM_HOME/bin"
  "$ANDROID_HOME/platform-tools"
  "$ANDROID_HOME/emulator"
  $path
)
export PATH

# Zinit
ZINIT_HOME="$XDG_DATA_HOME/zinit/zinit.git"
ZCOMPDUMP="$XDG_CACHE_HOME/zsh/.zcompdump"
source "$ZINIT_HOME/zinit.zsh"
