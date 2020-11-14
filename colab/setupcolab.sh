# Clone resources 
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm --depth 1
git clone https://github.com/hemanta212/dotfiles ~/dev/dotfiles

# setup exit script
wget https://hemanta212.github.io/dotfiles/colab/exit.sh
wget https://hemanta212.github.io/dotfiles/colab/manim.sh
chmod u+x ~/exit.sh
chmod u+x ~/manim.sh

# tmux and nvim init files
ln -s ~/dev/dotfiles/tmux/.tmux.conf ~/.tmux.conf
curl -sSL https://hemanta212.github.io/dotfiles/colab/resurrect.zip -o ~/.tmux/resurrector.zip 
cd ~/.tmux/ && unzip resurrector.zip
cd 

mkdir ~/.config/ && mkdir ~/.config/nvim && mkdir ~/.config/ptpython
curl -sLf https://spacevim.org/install.sh | bash
cp ~/dev/dotfiles/vim/space-vim/.SpaceVim.d/ -r ~/
cp ~/dev/dotfiles/emacs/.doom.d -r ~/

cp ~/dev/dotfiles/i3 -r ~/.i3
echo "i3" > .xsession

# zsh dotfiles
ln -s ~/dev/dotfiles/zsh/zsh ~/.config/zsh
cd ~/.config/zsh
wget https://hemanta212.github.io/dotfiles/colab/p10k.zsh
mkdir zsh-plugins
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git
git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git
git clone --depth=1 https://github.com/agkozak/zsh-z.git

# Prepare setup scripts
ln -s ~/dev/dotfiles/zsh/.pythonrc.py ~/.config/ptpython/.pythonrc.py
ln -s ~/dev/dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/dev/dotfiles/zsh/.bash_profile ~/.bash_profile
cd 

# setup git
cd ~/dev/dotfiles
git config --global user.email "sharmahemanta.212@gmail.com"
git config --global user.name "hemanta212"
cd
