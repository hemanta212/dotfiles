" Vim-plug initialization

let vim_plug_just_installed = 0
let vim_plug_path = expand('~/.config/nvim/autoload/plug.vim')
if !filereadable(vim_plug_path)
    echo "Installing Vim-plug..."
    echo ""
    silent !mkdir -p ~/.config/nvim/autoload
    silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    let vim_plug_just_installed = 1
endif

" manually load vim-plug the first time
if vim_plug_just_installed
    :execute 'source '.fnameescape(vim_plug_path)
endif

" ============================================================================
" this needs to be here, so vim-plug knows we are declaring the plugins we want to use
call plug#begin('~/.config/nvim/plugged')

Plug 'neovim/nvim-lspconfig'


" Tell vim-plug we finished declaring plugins, so it can load them
call plug#end()

" Install plugins the first time vim runs

if vim_plug_just_installed
    echo "Installing Bundles, please ignore key map error messages"
    :PlugInstall
endif

" ============================================================================
" Vim settings and mappings
" You can edit them as you wish

" tabs and spaces handling
"
" General Settings
"--------------------
set bs=indent,eol,start	" allow backspacing over everything in insert mode
set history=100		" keep 100 lines of command line history
set ruler			" show the cursor position all the time
set ar				" auto read when file is changed from outside
set nu				" show line numbers
set expandtab
set nohlsearch
set tabstop=4
set softtabstop=4
set shiftwidth=4
set guicursor=

" remove ugly vertical lines on window division
set fillchars+=vert:\

" auto reload vimrc when editing it
autocmd! bufwritepost .vimrc source ~/.vimrc

"auto reload file.
syntax on			" syntax highlight
set exrc
set nowrap       "Don't wrap lines
set linebreak    "Wrap lines at convenient points
set clipboard=unnamed	" yank to the system register (*) by default
set showmatch		" Cursor shows matching ) and }
set showmode		" Show current mode

"Telling vim where to split the screen when called :vs and :sp.
set splitbelow
set splitright

"Add utf-8 support default.
set encoding=utf-8

"Tabs to spaces *tab insert spaces*
set expandtab
set ts=2
"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

"Flagging Unnecessary Whitespace
highlight BadWhitespace ctermbg=red guibg=darkred
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/


"Resize things straight forward.
nmap < <C-w>< 
nmap > <C-w>>
nmap + <C-w>+
nmap - <C-w>-

"Remap esc to kj
imap kj <esc>
cnoremap kj <esc> 
nmap kj <esc>

" Move normally between wrapped lines
nmap j gj
nmap k gk
  
"write the file quick cmd.
nmap <Leader>s :write<Enter> :Format<Enter>
"quit quickly without writing.
nmap <Leader>q :q!<Enter>
"save and quit.
nmap <Leader>w :wq!<Enter>

lua << EOF
require'lspconfig'.pyright.setup{}
EOF
