export PATH="/usr/local/sbin:$PATH";

# Load dotfiles:
for file in ~/.{bash_prompt,aliases}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

#Git auto-complete
if [ -d ~/.pyenv/bin ]; then
  export PATH="~/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
#  eval "$(pyenv virtualenv-init -)"
  export PYENV_ROOT='~/.pyenv/'
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
  if [ $# -eq 0 ]
    then
      source $(poetry env info -p)/bin/activate
  fi
}

menv () {
      python -m venv ~/.cache/pypoetry/virtualenvs/$1;
}

neovim () {
    current=$PWD
    cd ~/$1;
    aenv;
    cd $current;
    echo $current;
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

export PATH="$HOME/.poetry/bin:$PATH"

for file in ~/.{pyenv/completions/pyenv.bash,bashrc_local}; do

  if [ -f "$file" ]; then
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
  fi
done;
unset file;

