export PATH="/usr/local/sbin:$PATH";

# Load dotfiles:
for file in ~/.{bash_prompt,aliases}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

for file in ~/.{pyenv/completions/pyenv.bash, git-completion.bash}; do
  if [ -f "$file" ]; then
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
  fi
done;
unset file;

#Git auto-complete
if [ -d /home/h/.pyenv/bin ]; then
  export PATH="/home/h/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
  export PYENV_ROOT='/home/h/.pyenv/'
fi

upvrc() {
    cd ~;
    cp .vimrc ~/dotfiles/vim/vim/;
    cd  ~/.vim/ ;
    cp init.vimrc general.vimrc python.vimrc plugin.vimrc graphics.vimrc key.vimrc ~/dotfiles/vim/vim/;
    cd ~/dotfiles/
    git add . && git commit -m "updated vim configs" 
    cd ;
}

upnvim() {
    cd ~/.config/nvim/;
    cp init.vim ~/dotfiles/vim/neovim/;

    cd ~/dotfiles/
    git add . && git commit -m "updated neovim configs"
    cd ;
}
aenv () {
  if [ $# -eq 1 ]
    then
      source ~/.cache/pypoetry/virtualenvs/$1/bin/activate
  fi
  if [ $# -eq 1 ]
    then
      source $(poetry env info -p)/bin/activate
  fi
}

cenv () {
      python -m venv /home/.py
}

neovim () {
    current=${PWD##*/}
    cd ~/$1;
    aenv;
    cd current;
    if [ $# -eq 1 ]
        then
           nvim; 
    fi
    if [ $# -eq 2 ]
        then
           nvim $2; 
    fi
}

dpvrc() {
    cd ~/dotfiles/vim/vim/;
    cp .vimrc init.vimrc general.vimrc python.vimrc plugin.vimrc graphics.vimrc key.vimrc ~/.vim/;
    cd ;
}

dpnvim() {
    cd ~/dotfiles/vim/neovim/;
    cp init.vim ~/.config/nvim/
    cd ;
}


sbash () {
      source ~/.bashrc
}
upbash () {
      cd ~
      cp .bashrc .bash_profile .aliases .tmux.conf .bash_prompt ~/dotfiles/bash/linux/
      cd ~/dotfiles/
      git add . && git commit -m "updated bash dotfiles"
}
dpbash() {
        cd ~/dotfiles/bash/linux/
        cp .bashrc .aliases .bash_prompt .tmux.conf .bash_profile  ~/
}
        
updotfiles () {
        cd ~/dotfiles/
        git pull origin master
        git push origin master
}
clone() {
        cd 
        git clone https://github.com/$1/$2
}
vrc (){
        vim ~/.vim/$1.vimrc
}
vbash (){
        vim ~/.bashrc
}
valias (){
        vim ~/.aliases
}

vprof (){
        vim ~/.bash_profile
}

vwake(){
    source bin/activate
}
cenv () {
        poetry init $1 
        cd $1
}

function extract {
 if [ -z "$1" ]; then
	     # display usage if no parameters given
			     echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
					     echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
							     return 1
									  else
											    for n in $@
														    do
																	      if [ -f "$n" ] ; then
																					          case "${n%,}" in
																											            *.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar) 
																																		                         tar xvf "$n"       ;;
																																														             *.lzma)      unlzma ./"$n"      ;;
																																																				             *.bz2)       bunzip2 ./"$n"     ;;
																																																										             *.rar)       unrar x -ad ./"$n" ;;
																																																																             *.gz)        gunzip ./"$n"      ;;
																																																																						             *.zip)       unzip ./"$n"       ;;
																																																																												             *.z)         uncompress ./"$n"  ;;
																																																																																		             *.7z|*.arj|*.cab|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.rpm|*.udf|*.wim|*.xar)
																																																																																									                          7z x ./"$n"        ;;
																																																																																																						            *.xz)        unxz ./"$n"        ;;
																																																																																																												            *.exe)       cabextract ./"$n"  ;;
																																																																																																																		            *)
																																																																																																																									                         echo "extract: '$n' - unknown archive method"
																																																																																																																																					                          return 1
																																																																																																																																																		                         ;;
																																																																																																																																																														           esac
																																																																																																																																																																			       else
																																																																																																																																																																							           echo "'$n' - file does not exist"
																																																																																																																																																																												           return 1
																																																																																																																																																																																	       fi
																																																																																																																																																																																				     done
																																																																																																																																																																																					 fi
																																																																																																																																																																																				 }

export PATH="$HOME/.poetry/bin:$PATH"
