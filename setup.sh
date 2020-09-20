# Clone resources 
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm --depth 1
git clone https://github.com/hemanta212/dotfiles ~/dev/dotfiles

cp ~/dev/dotfiles/tmux/.tmux.conf ~/

mkdir ~/.config/ && mkdir ~/.config/nvim && mkdir ~/.config/ptpython
curl -sLf https://spacevim.org/install.sh | bash
cp ~/dev/dotfiles/vim/space-vim/.SpaceVim.d/ -r ~/

# zsh dotfiles
cp -r ~/dev/dotfiles/zsh/zsh ~/.config/
git clone https://github.com/romkatv/powerlevel10k ~/.config/zsh/powerlevel10k --depth 1

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
