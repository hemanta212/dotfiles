mkdir -p ~/.config/ && mkdir -p ~/.config/nvim && mkdir -p ~/.config/ptpython && mkdir -p ~/.config/zsh/

# Clone resources 
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm --depth 1
git clone https://github.com/hemanta212/dotfiles ~/dev/dotfiles
git clone https://github.com/romkatv/powerlevel10k ~/.config/zsh/powerlevel10k --depth 1

curl -sSL https://hemanta212.github.io/dotfiles/colab/p10k.zsh -o ~/.config/zsh/p10k.zsh

ln -s ~/dev/dotfiles/tmux/.tmux.conf ~/
DOT_PREFIX = "~/dev/dotfiles/zsh"
ln -s ~/dev/dotfiles/zsh/zsh/* ~/.config/zsh/
ln -s $DOT_PREFIX/pythonrc.py ~/.config/ptpython/
ln -s  $DOT_PREFIX/.zshrc $DOT_PREFIX/.bashrc $DOT_PREFIX/.bash_profile ~/

# setup git
cd ~/dev/dotfiles
git config --global user.email "sharmahemanta.212@gmail.com"
git config --global user.name "hemanta212"
cd
