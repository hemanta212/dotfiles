# Clone resources 
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm --depth 1
git clone https://github.com/hemanta212/dotfiles ~/dev/dotfiles


# tmux and nvim init files
cp ~/dev/dotfiles/tmux/.tmux.conf ~/
mkdir ~/.config/ && mkdir ~/.config/nvim && mkdir ~/.config/ptpython
cp ~/dev/dotfiles/vim/neovim/init_heavy.vim ~/.config/nvim/init.vim

# zsh dotfiles
cp -r ~/dev/dotfiles/zsh/zsh ~/.config/
git clone https://github.com/romkatv/powerlevel10k ~/.config/zsh/powerlevel10k --depth 1

# Prepare setup scripts
cd ~/dev/dotfiles/
git checkout colab
cp colab/.p10k.zsh ~/zsh/p0k.zsh
git checkout master
cd zsh
cp .pythonrc.py ~/.config/ptpython/
cp .zshrc .bashrc ~/

# setup git
cd ~/dev/dotfiles
git config --global user.email "sharmahemanta.212@gmail.com"
git config --global user.name "hemanta212"
cd ~/

# Get sdkmanager cli and install android-sdk
wget https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip
unzip commandlinetools-linux-6609375_latest.zip
rm commandlinetools-linux-6609375_latest.zip
mkdir local/ && mkdir local/android-sdk && mkdir local/android-sdk/cmdline-tools
mv tools local/android-sdk/cmdline-tools/

# Export the Android SDK path 
export ANDROID_HOME=$HOME/local/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

sdkmanager "platform-tools"  "platforms;android-28" "platforms;android-29" "build-tools;28.0.3"
sudo update-alternatives --config java

# Flutter
git clone https://github.com/flutter/flutter ~/local/flutter --depth 1
export PATH="$PATH":"$HOME/local/flutter/bin/"
flutter
flutter doctor
flutter doctor --android-licenses
flutter doctor

python -m venv .pyvenv
sudo .pyvenv/bin/python -m pip install ptpython requests 
