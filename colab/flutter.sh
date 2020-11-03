mkdir ~/dev
cd ~/dev
git clone https://github.com/hemanta212/hello_flutter.git
git clone https://github.com/hemanta212/inventory_app.git
cd hello_flutter/
git config --global credential.helper store
git push origin master
cd ~/dev

git clone https://github.com/hemanta212/samachar_app.git
git clone https://github.com/hemanta212/meme_khani.git
git clone https://github.com/hemanta212/marriage-card-tracker.git card_tracker

cd card_tracker 
git checkout next
cp ~/dev/personal/credentials/marriage_card_tracker/* android/app/
mv android/app/key.properties android/
cd 
cp dev/card_tracker ~/  -r


# Flutter
git clone https://github.com/flutter/flutter ~/local/flutter
cd ~/local/flutter && git checkout beta && cd
export PATH="$PATH":"$HOME/local/flutter/bin/"
flutter channel beta
flutter upgrade
flutter doctor
yes | flutter doctor --android-licenses
flutter config --enable-web
flutter doctor

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

yes | sdkmanager "platform-tools"  "build-tools;28.0.3" "platforms;android-29"


