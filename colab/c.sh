cd ~/dev/
git clone https://github.com/hemanta212/c-practice
git clone https://github.com/hemanta212/lisp-in-c
git clone https://github.com/hemanta212/hash-table-in-c
git clone https://github.com/hemanta212/personal
cd 

#git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d 
#yes | ~/.emacs.d/bin/doom install
rm -rf ~/.emacs.d
mkdir ~/.emacs.d
ln -s ~/dev/dotfiles/emacs/.emacs.d/* ~/.emacs.d/
emacs
