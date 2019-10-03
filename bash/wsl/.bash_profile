export PATH="$HOME/.poetry/bin:$PATH"
export PATH="$HOME/local/.blogger_cli/bin:$PATH"

# Load dotfiles:
for file in ~/.{bash_prompt,aliases}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

export DISPLAY=192.168.1.13:1
export LIBGL_ALWAYS_INDIRECT=1

export PATH="/usr/local/sbin:$PATH";

#Git auto-complete
if [ -f ~/.git-completion.bash ]; then
    source ~/.git-completion.bash
fi

aenv () {
  if [ $# -eq 1 ]
    then
      source ~/.virtualenvs/$1/bin/activate
  fi
  if [ $# -eq 0 ]
    then
      source $(poetry env info -p)/bin/activate
  fi
}

menv () {
      python -m venv ~/.virtualenvs/$1;
}

neovim () {
    cd ~/$1;
    aenv;
    if [ $# -eq 1 ]
        then
           nvim; 
    fi
    if [ $# -eq 2 ]
        then
           nvim $2; 
    fi

}

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

upbash () {
      cd ~
      cp .bashrc .bash_profile .aliases .tmux.conf .bash_prompt ~/dotfiles/pc-vim/wsl/
      cd ~/dotfiles/
      git add . && git commit 
}
dpbash() {
        cd ~/dotfiles/pc-vim/wsl/
        cp .bashrc .aliases .bash_prompt .tmux.conf .bash_profile  ~/
}
        
updotfiles () {
        cd ~/dotfiles/
        git pull origin master
        git push origin master
}

clone() {
        git clone https://github.com/$1/$2
}

vrc (){
        vim ~/.vim/$1.vimrc
}

display (){
    export DISPLAY=localhost:$1
}

