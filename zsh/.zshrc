# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Some sorcery /////////SOURCING other files //////////////////////
for file in ~/.config/zsh/{zshrc,functionsrc,aliases,p10k.zsh,.mytermuxrc,.mywslrc,.mycolabrc};
 do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

for file in ~/.config/zsh/zsh-plugins/{powerlevel10k/powerlevel10k.zsh-theme,zsh-autosuggestions/zsh-autosuggestions.zsh,zsh-history-substring-search/zsh-history-substring-search.zsh,zsh-z/zsh-z.plugin.zsh};
 do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Load zsh-syntax-highlighting; should be last.
source ~/.config/zsh/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
