cd ~/dev/dotfiles
git config credential.helper store
git push origin master

cd ~/dev/
git clone https://github.com/hemanta212/c-practice
git clone https://github.com/hemanta212/personal
cd c-practice/clisp

git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d 
~/.emacs.d/bin/doom install
