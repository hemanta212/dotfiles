sudo /etc/init.d/xrdp restart

# Clone resources 
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm --depth 1
git clone https://github.com/hemanta212/dotfiles ~/dev/dotfiles

# setup exit script
curl -sSL https://hemanta212.github.io/dotfiles/colab/exit.sh -o ~/exit.sh
chmod u+x ~/exit.sh

# tmux and nvim init files
cp ~/dev/dotfiles/tmux/.tmux.conf ~/
curl -sSL https://hemanta212.github.io/dotfiles/colab/resurrect.zip -o ~/.tmux/resurrector.zip 
cd ~/.tmux/ && unzip resurrector.zip
cd 

mkdir ~/.config/ && mkdir ~/.config/nvim && mkdir ~/.config/ptpython
curl -sLf https://spacevim.org/install.sh | bash
cp ~/dev/dotfiles/vim/space-vim/.SpaceVim.d/ -r ~/
cp ~/dev/dotfiles/emacs/.doom.d -r ~/

cp ~/dev/dotfiles/i3/ -r ~/
echo "i3" > .xsession

# zsh dotfiles
cp -r ~/dev/dotfiles/zsh/zsh ~/.config/
git clone https://github.com/romkatv/powerlevel10k ~/.config/zsh/powerlevel10k --depth 1

# Prepare setup scripts
curl -sSL https://hemanta212.github.io/dotfiles/colab/p10k.zsh -o ~/.config/zsh/p10k.zsh
cd ~/dev/dotfiles/zsh
cp .pythonrc.py ~/.config/ptpython/
cp .zshrc .bashrc .bash_profile ~/
cd 

# setup git
cd ~/dev/dotfiles
git config --global user.email "sharmahemanta.212@gmail.com"
git config --global user.name "hemanta212"
cd
