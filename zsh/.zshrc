# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#================
#ZPLUG

#INSTALLATION
# curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

# By default zplug pollutes home directory ie .zplug
export ZPLUG_HOME=$HOME/.cache/zplug
source ~/.cache/zplug/init.zsh

zplug 'zplug/zplug', hook-build:'zplug --self-manage'
# Make sure to use double quotes
# zplug "zsh-users/zsh-history-substring-search"
zplug "romkatv/powerlevel10k", as:theme, depth:1
zplug "zsh-users/zsh-autosuggestions", depth:1

# Disable updates using the "frozen" tag
# zplug "k4rthik/git-cal", as:command, frozen:1

# # Supports oh-my-zsh plugins and the like
# zplug "plugins/git",   from:oh-my-zsh

# # Also prezto
# zplug "modules/prompt", from:prezto

# Load if "if" tag returns true
# zplug "lib/clipboard", from:oh-my-zsh, if:"[[ $OSTYPE == *darwin* ]]"

# Supports checking out a specific branch/tag/commit
# zplug "b4b4r07/enhancd", at:v1
# zplug "mollifier/anyframe", at:4c23cb60

# Set the priority when loading
# e.g., zsh-syntax-highlighting must be loaded
# after executing compinit command and sourcing other plugins
# (If the defer tag is given 2 or above, run after compinit command)
zplug "zsh-users/zsh-syntax-highlighting", defer:2

# Can manage local plugins
zplug "$HOME/dev/dotfiles/zsh/zsh", from:local

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load #--verbose

# Some sorcery /////////SOURCING other files //////////////////////
for file in ~/dev/dotfiles/zsh/zsh/{functionsrc,aliases,.mytermuxrc,.mycolabrc,claude.zsh,zshrc};
 do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# bun completions
[ -s "/Users/mac/.bun/_bun" ] && source "/Users/mac/.bun/_bun"

autoload -Uz compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc

. "$HOME/.cargo/env"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /Users/mac/.config/.dart-cli-completion/zsh-config.zsh ]] && . /Users/mac/.config/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

#export JAVA_HOME='/Users/mac/Library/Application Support/neo4j-desktop/Application/Cache/runtime/zulu21.44.17-ca-jdk21.0.8-macosx_aarch64/zulu-21.jdk/Contents/Home' 
