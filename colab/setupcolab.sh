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
git config --global credential.helper store
git push origin master
cd

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

python -m venv .ptvenv
sudo .ptvenv/bin/python -m pip install ptpython requests 
