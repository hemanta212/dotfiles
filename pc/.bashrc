# /////////////-----------------MY Aliases (hemanta sharma).......///////////////
#/////////////////////////////////////////////////////////////////////////////////

alias jn='jupyter notebook --allow-root'

#///////////..............MY functions/////////////////////
#///////////////////////////////////////////////

c (){
  cd ~
	mkdir /my_projects/$1/$2
	git init /my_projects/$1/$2
}

v () {
 vim ~/my_projects/$1/$2
}

o () {
 cd ~/my_projects/$1/$2
 ls
}

d (){
	rm -rf ~/my_projects/$1/$2
}

cv (){
	c $1 $2
	v $1 $2	
}

co (){
	c $1 $2
	o $1 $2
}
ov () {
    o $1 $2 
    v $1 $2
} 
home () {
	cd ~
	 
}

vbash (){
        vim ~/.bashrc
}
vrc (){
        vim ~/.vimrc
}

lpy (){
        cd /lpy/
        jn
}
vwake(){
    source bin/activate
}
cenv () {
        virtualenv $1 
        cd $1
        vwake
        mkdir $2
        cd $2
}
sbash () {
      source ~/.bashrc
}
upvrc () {
      cp ~/.vimrc /dotfiles/gnuroot/ 
      cd /dotfiles/
      git add -A && git commit -m "added configs to my vimrc of gnuroot"
}
upbash () {
      cp ~/.bashrc /dotfiles/gnuroot/
      cd /dotfiles/
      git add -A && git commit -m "added configs to my bashrc of gnuroot"
}
dpbash() {
        cp /dotfiles/gnuroot/.bashrc ~/
        
}
dpvrc () {
        cp /dotfiles/gnuroot/.vimrc ~/
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
