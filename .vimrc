set nocompatible              " required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" add all your plugins here (note older versions of Vundle
" used Bundle instead of Plugin)

"PLUGINS LIST:

"plugin related to folding (from realpython.1st addition.)
    Plugin 'tmhedberg/SimpylFold'
"plugin for autoidentation in python.
    Plugin 'vim-scripts/indentpython.vim'
"Plugin for syntax highlightion.
    Plugin 'vim-syntastic/syntastic'
"PEP-8 checking syntax plugin.
    Plugin 'nvie/vim-flake8'
"Autocomplettion plugin by Neo.
    Plugin 'shougo/neocomplete.vim'
"plugin for theme Zenburn for CLI and another for GUI.(its logic is below).
    Plugin 'jnurmine/Zenburn'
    Plugin 'altercation/vim-colors-solarized'
"Inside File browsing using NerdTree plugin.
    Plugin 'scrooloose/nerdtree'
"Utilize tabs in NerdTree
    Plugin 'jistr/vim-nerdtree-tabs'
"TO search basically anything from vim.(Use it by ctrl + p.
    Plugin 'kien/ctrlp.vim'
"Enable Basic git cmds inside the vim.
    Plugin 'tpope/vim-fugitive'
"Enable the powerline (basic file info at buttom. (  :) My dream!!)
   Plugin 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
" ...

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
"To use powershell inside the vim editor.
    set  rtp+=/usr/local/lib/python3.4/dist-packages/powerline/bindings/vim/
    set laststatus=2
    set t_Co=256
"Set clipboard so that to copy,paste and cut in interapps.(not only in vim)
    set clipboard=unnamed

"Line Numbering!!!!! YAY!
    set nu

"Telling vim where to split the screen when called vs and (i forgot). 
set splitbelow
set splitright

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

"Enable folding
set foldmethod=indent
set foldlevel=99

" Enable folding with the spacebar
nnoremap <space> za

"Flagging Unnecessary Whitespace
highlight BadWhitespace ctermbg=red guibg=darkred
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

"Add utf-8 support default.
set encoding=utf-8

"Manage Auto identation acc to PEP-8
au BufNewFile,BufRead *.py
    \ set tabstop=4 |
    \ set softtabstop=4 |
    \ set shiftwidth=4 |
    \ set textwidth=79 |
    \ set expandtab |
    \ set autoindent |
    \ set fileformat=unix 

"Identation for HTML, CSS and JS
au BufNewFile,BufRead *.js, *.html, *.css
    \ set tabstop=2
    \ set softtabstop=2
    \ set shiftwidth=2

"Activate syntax highlight and make code pretty.
    let python_highlight_all=1
    syntax on
"Choose which theme to use with logic.
"    if has('gui_running')
"       set background=dark
"       colorscheme solarized
"    else
"       colorscheme zenburn
"    endif 
"switching bet black and white solarized theme bg with f5..
"    call togglebg#map("<F5>")
"Hiding .pyc in Nerdtree.
    let NERDTreeIgnore=['\.pyc$', '\~$'] "ignore files in NERDTree

"Enabel neocomplete autocomplete feature by default.
    let g:neocomplete#enable_at_startup = 1

"python with virtualenv support
py << EOF
import os
import sys
if 'VIRTUAL_ENV' in os.environ:
  project_base_dir = os.environ['VIRTUAL_ENV']
  activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
  execfile(activate_this, dict(__file__=activate_this))
EOF

"Key mapping for VIM.
inoremap kj <esc>
cnoremap kj <esc> 
