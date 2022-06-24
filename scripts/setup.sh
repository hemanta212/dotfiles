mkdir -p $HOME/.config/ && mkdir -p $HOME/.config/nvim && mkdir -p $HOME/.config/ptpython && mkdir -p $HOME/.config/zsh/ -p $HOME/.config/emacs && mkdir -p $HOME/scripts


# Clone resources 
git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm --depth 1
git clone https://github.com/hemanta212/dotfiles $HOME/dev/dotfiles
git clone https://github.com/romkatv/powerlevel10k $HOME/.config/zsh/powerlevel10k --depth 1

curl -sSL https://hemanta212.github.io/dotfiles/colab/p10k.zsh -o $HOME/.config/zsh/p10k.zsh

ln -s $HOME/dev/dotfiles/scripts/* $HOME/scripts/
ln -s $HOME/dev/dotfiles/tmux/.tmux.conf $HOME/
DOT_PREFIX="$HOME/dev/dotfiles/zsh"
ln -s $HOME/dev/dotfiles/zsh/zsh/* $HOME/.config/zsh/
ln -s $DOT_PREFIX/pythonrc.py $HOME/.config/ptpython/
cp $HOME/dev/dotfiles/zsh/.pythonrc.py .config/ptpython
ln -s $DOT_PREFIX/.zshrc $HOME
ln -s $DOT_PREFIX/.bashrc $DOT_PREFIX/.bash_profile $HOME
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
wget https://github.com/dandavison/delta/releases/download/0.12.1/git-delta_0.12.1_amd64.deb -O $HOME/git-delta.deb
export PATH=$PATH:$HOME/.cache/zplug/bin/
curl -sS https://webinstall.dev/zoxide | zsh

# setup git
cd $HOME/dev/dotfiles
git config --global user.email "sharmahemanta.212@gmail.com"
git config --global user.name "hemanta212"
cd

ln -s $HOME/dev/dotfiles/emacs/snippets $HOME/.config/emacs/
ln -s $HOME/dev/dotfiles/emacs/.emacs.d/{init.el,config.org} $HOME/.config/emacs/
ln -s $HOME/dev/dotfiles/neovim/{init.lua,init.org} $HOME/.config/nvim/

sudo apt install fasd
zsh
