clear
cd
export PATH="/usr/local/sbin:$PATH";
export PATH="$HOME/anaconda/bin:$PATH";

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
    cp .vimrc ~/dotfiles/gnuroot/;
    cd  ~/.vim/ ;
    cp init.vimrc general.vimrc python.vimrc plugin.vimrc graphics.vimrc key.vimrc ~/dotfiles/gnuroot/;
    cd ~/dotfiles/
    git add . && git commit -m "updated vim files"
    cd ;
}

dpvrc() {
    cd ~/dotfiles/gnuroot/;
    cp .vimrc init.vimrc general.vimrc python.vimrc plugin.vimrc graphics.vimrc key.vimrc ~/.vim/;
    cd ;
}

#c (){
#	mkdir /sdcard/my_projects/$1/$2
#	git init /sdcard/my_projects/$1/$2
#}

#v () {
# vim /sdcard/my_projects/$1/$2
#}
#
#o () {
# cd /sdcard/my_projects/$1/$2
# ls
#}
#
#d (){
#	rm -rf /sdcard/my_projects/$1/$2
#}
#
#cv (){
#	c $1 $2
#	v $1 $2	
#}
#
#co (){
#	c $1 $2
#	o $1 $2
#}
#ov () {
#    o $1 $2 
#    v $1 $2
#} 
# open dump folder for testing purposers practice etc
dump (){
    vim /sdcard/my_projects/dumps/$1
}
home () {
	cd ~
	cd ../
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
        virtualenv $1 
        cd $1
        vwake
        cd $2
}
sbash () {
      source ~/.bashrc
}
upbash () {
      cd ~
      cp .bashrc .bash_profile .aliases .bash_prompt ~/dotfiles/gnuroot/
      cd ~/dotfiles/
      git add . && git commit -m "added configs to my bashrc of gnuroot"
}
dpbash() {
        cd ~/dotfiles/gnuroot/
        cp .bashrc .aliases .bash_prompt .bash_profile  ~/
        
}
clone() {
        cd 
        git clone https://github.com/$1/$2
}
        
sd (){
        cd /~/sdcard/

}
updotfiles () {
        cd ~/dotfiles/
        git pull origin master
        git push origin master
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
