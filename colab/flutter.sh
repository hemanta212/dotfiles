mkdir ~/dev
# Get sdkmanager cli and install android-sdk
wget https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip
unzip commandlinetools-linux-6609375_latest.zip
rm commandlinetools-linux-6609375_latest.zip
mkdir local/
mkdir local/android-sdk
mkdir local/android-sdk/cmdline-tools
mv tools local/android-sdk/cmdline-tools/

# Export the Android SDK path 
export ANDROID_HOME=$HOME/local/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

sdkmanager "platform-tools"  "platforms;android-28" "platforms;android-29" "build-tools;28.0.3"

# Flutter
git clone https://github.com/flutter/flutter ~/local/flutter
cd ~/local/flutter && git checkout stable && cd
export PATH="$PATH":"$HOME/local/flutter/bin/"
flutter
flutter doctor
flutter doctor --android-licenses
flutter doctor

cd ~/dev
git clone https://github.com/hemanta212/hello_flutter.git
git clone https://github.com/hemanta212/inventory_app.git
cd hello_flutter/
git config --global credential.helper store
git push origin master
cd ~/dev

git clone https://github.com/hemanta212/samachar_app.git
