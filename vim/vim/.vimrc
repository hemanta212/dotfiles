"MY VIMRC IS MODULAR 
"CALLING ALL VIMRC FILE PARTS ..........
source ~/.vim/init.vimrc
source ~/.vim/plugin.vimrc
source ~/.vim/general.vimrc
source ~/.vim/python.vimrc
source ~/.vim/key.vimrc
source ~/.vim/graphics.vimrc

" auto reload vimrc when editing vimrc or its parts 
autocmd! bufwritepost .vimrc source ~/.vimrc
autocmd! bufwritepost plugin.vimrc source ~/.vimrc
autocmd! bufwritepost key.vimrc source ~/.vimrc
autocmd! bufwritepost graphics.vimrc source ~/.vimrc
autocmd! bufwritepost python.vimrc source ~/.vimrc

if !empty(glob("%:p:h/.custom.vim"))
  source %:p:h/.vim
  autocmd! bufwritepost .vim source ~/.vimrc
else
  autocmd! bufwritepost .vim source .vim
endif

"....................END..............
"///////////////////////////////////
"LASTLY >>>>>>>>>
"Add this to ~/.inputrc to use vim in shell.
"set editing-mode vi
let g:python3_host_prog='/home/hs/.local/share/virtualenvs/flask-hNL7gVvz/bin/python3.6'

