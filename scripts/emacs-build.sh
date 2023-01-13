#!/usr/bin/env bash

## Author: Abidán Brito
## This script builds GNU Emacs 28 with support for native elisp compilation,
## libjansson (C JSON library) and mailutils.

# Exit on error and print out commands before executing them.
set -euxo pipefail 

# Let's set the number of jobs to something reasonable; keep 2 cores
# free to avoid choking the computer during compilation.
JOBS=`nproc --ignore=2`

# Clone repo locally and get into it.
#git clone --branch master git://git.savannah.gnu.org/emacs.git --depth 1
pushd emacs

# Get essential dependencies.
sudo apt install -y build-essential \
    texinfo \
    libgnutls28-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff5-dev \
    libgif-dev \
    libxpm-dev \
    libncurses-dev \
    libgtk-3-dev
    #libwebkit2gtk-4.0-dev
    #libmagick++-dev

# Get dependencies for gcc-10 and the build process.
sudo apt update -y
sudo apt install -y gcc-10 \
    g++-10 \
    libgccjit0 \
    libgccjit-10-dev

# Get dependencies for fast JSON.
sudo apt install -y libjansson4 libjansson-dev

# Get GNU Mailutils (protocol-independent mail framework).
sudo apt install -y mailutils

# Enable source packages and get dependencies for whatever 
# Emacs version Ubuntu supports by default.
#
# Taken from here:
# https://www.masteringemacs.org/article/speed-up-emacs-libjansson-native-elisp-compilation
#sudo sed -i 's/# deb-src/deb-src/' /etc/apt/sources.list \
#    && apt update \
#    && apt build-dep -y emacs

# Stop debconf from complaining about postfix nonsense.
DEBIAN_FRONTEND=noninteractive

# Needed for compiling libgccjit or we'll get cryptic error messages.
export CC=/usr/bin/gcc-10 CXX=/usr/bin/g++-10

# Configure and run.
#
# Compiler flags:
# -O2 -> Turn on a bunch of optimization flags. There's also -O3, but it increases
#        the instruction cache footprint, which may end up reducing performance.
# -pipe -> Reduce temporary files to the minimum.
# -mtune=native -> Optimize code for the local machine (under ISA constraints).
# -march=native -> Enable all instruction subsets supported by the local machine.
# -fomit-frame-pointer -> I'm not sure what this does yet...
#
# NOTE(abi): binaries should go to /usr/local/bin by default.
./autogen.sh \
    && ./configure \
    --with-native-compilation \
    --with-json \
    --with-gnutls \
    --with-mailutils \
    --with-pgtk \
    --with-xwidgets \
    --with-x-toolkit=no \
    --with-imagemagick \
    --with-jpeg --with-png --with-rsvg --with-tiff \
    --with-xml2 \
    --with-cairo \
    --with-modules \
    --without-compress-install \
    --without-xaw3d \
    --without-gconf \
    --without-gsettings \
    --with-wide-int \
    --with-xft \
    --with-xm2 \
    --with-xpm \
    CFLAGS="-O3 -pipe -mtune=native -march=native -fomit-frame-pointer" prefix=/usr/local
    
    # Other interesting compilation options:
    #
        #--with-x-toolkit=gtk3

# Build.
#
# NOTE(abi): NATIVE_FULL_AOT=1 ensures native compilation ahead-of-time for all
#            elisp files included in the distribution.
make -j${JOBS} && sudo make install

# Return to the original path.
popd
