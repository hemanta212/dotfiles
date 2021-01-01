cd ~/ || exit

sudo apt install libxpm-dev libgif-dev libjpeg-dev libpng-dev libtiff-dev libx11-dev libncurses5-dev automake autoconf texinfo libgtk2.0-dev 
sudo add-apt-repository ppa:ubuntu-toolchain-r/ppa -y
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
sudo apt-get update
sudo apt install gcc-10 g++-10 libgccjit0 libgccjit-10-dev libjansson4 libjansson-dev libgnutls28-dev
git clone git://git.sv.gnu.org/emacs.git
cd emacs || exit
git checkout feature/native-comp
export CC=/usr/bin/gcc-10 CXX=/usr/bin/gcc-10
./autogen.sh
./configure --with-nativecomp --with-json CFLAGS="-O3 -mtune=native -march=native -fomit-frame-pointer"
#./configure --with-nativecomp --with-json --with-gnutls --without-gconf --with-rsvg --with-x --with-xwidgets --without-toolkit-scroll-bars --without-xaw3d --without-gsettings --with-mailutils CFLAGS="-O3 -mtune=native -march=native -fomit-frame-pointer"

sudo make -j2 NATIVE_FULL_AOT=1
sudo make install

sudo update-alternatives --install /usr/bin/emacs emacs /usr/local/bin/emacs 5000

mv ~/.emacs.d ~/.emacs.d.bak
cp -r ~/dev/dotfiles/emacs/.emacs.d ~/
./src/emacs
