export PATH="/usr/local/sbin:$PATH";

# Load dotfiles:
for file in ~/.{bash_prompt,aliases}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

#Git auto-complete
if [ -f ~/.git-completion.bash ]; then
    source ~/.git-completion.bash
fi

upvrc() {
    cd ~;
    cp .vimrc ~/dotfiles/pc-vim/;
    cd  ~/.vim/ ;
    cp init.vimrc general.vimrc python.vimrc plugin.vimrc graphics.vimrc key.vimrc ~/dotfiles/pc-vim/;
    cd ~/dotfiles/
    git add . && git commit 
    cd ;
}

dpvrc() {
    cd ~/dotfiles/pc-vim/;
    cp .vimrc init.vimrc general.vimrc python.vimrc plugin.vimrc graphics.vimrc key.vimrc ~/.vim/;
    cd ;
}

sbash () {
      source ~/.bashrc
}
upbash () {
      cd ~
      cp .bashrc .bash_profile .aliases .tmux.conf .bash_prompt ~/dotfiles/pc-vim/
      cd ~/dotfiles/
      git add . && git commit 
}
dpbash() {
        cd ~/dotfiles/pc-vim/
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
vprofile (){
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
