set nocompatible              " required
filetype off                  " required

" set the runtime path to include Vundle and initialize to intall vundle first do git clone ht"tps://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim in the terminal.
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" add all your plugins here (note older versions of Vundle
" used Bundle instead of Plugin)

"PLUGINS LIST:

"Plugin for syntax highlightion.
    Plugin 'vim-syntastic/syntastic'
"Inside File browsing using NerdTree plugin.
    Plugin 'scrooloose/nerdtree'
"Utilize tabs in NerdTree
    Plugin 'jistr/vim-nerdtree-tabs'
"TO search basically anything from vim.(Use it by ctrl + p.
    Plugin 'kien/ctrlp.vim'
"Enable Basic git cmds inside the vim.
    Plugin 'tpope/vim-fugitive'
"EMMET plugin for vim.
		Plugin 'mattn/emmet-vim'
					
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
"--------------------
" General Settings
"--------------------
set bs=indent,eol,start	" allow backspacing over everything in insert mode
set history=100		" keep 100 lines of command line history
set ruler			" show the cursor position all the time
set ar				" auto read when file is changed from outside
set nu				" show line numbers
" auto reload vimrc when editing it
autocmd! bufwritepost .vimrc source ~/.vimrc

syntax on			" syntax highlight
set hlsearch		" search highlighting

" terminal color settings
if has("gui_running")	" GUI color and font settings
	set guifont=Courier:h18
	set background=dark 
	set t_Co=256		" 256 color mode
	set cursorline	" highlight current line
	highlight CursorLine  guibg=#003853 ctermbg=24  gui=none cterm=none
	colors moria
else
	colors evening
endif

set clipboard=unnamed	" yank to the system register (*) by default
set showmatch		" Cursor shows matching ) and }
set showmode		" Show current mode
" FOLDING
set foldenable
set foldmethod=marker
set foldlevel=0
set foldcolumn=0

" status line
set laststatus=2
set statusline=\ %{HasPaste()}%<%-15.25(%f%)%m%r%h\ %w\ \ 
set statusline+=\ \ \ [%{&ff}/%Y] 
set statusline+=\ \ \ %<%20.30(%{hostname()}:%{CurDir()}%)\ 
set statusline+=%=%-10.(%l,%c%V%)\ %p%%/%L

fun! CurDir()
	let curdir = substitute(getcwd(), $HOME, "~", "")
	return curdir
endfun

fun! HasPaste()
	if &paste
		return '[PASTE]'
	else
		return ''
	endif
endfun
"Telling vim where to split the screen when called :vs and :sp.
set splitbelow
set splitright

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

set tabstop=2
set softtabstop=2
set shiftwidth=2


"Identation for HTML, CSS and JS
au BufNewFile,BufRead *.js, *.html, *.css
    \ set tabstop=2
    \ set softtabstop=2
    \ set shiftwidth=2

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

"Remap esc to kj
imap kj <esc>
cnoremap kj <esc> 
nmap kj <esc>

set nowrap       "Don't wrap lines
set linebreak    "Wrap lines at convenient points

" Move normally between wrapped lines
nmap j gj
nmap k gk

"......NERDTree Setup...............
"Open directly to curently working file by \v
nnoremap <silent> <Leader>v :NERDTreeFind<CR>

"close after selecting one file to open.
let NERDTreeQuitOnOpen = 1

"Automaticlaly close tab if only nerdtree isopen
"autocmd bufenter * if (winnr(“$”) == 1 && exists(“b:NERDTreeType”) &&
"b:NERDTreeType == “primary”) | q | endif

"Delete the buffer of file you delleted.
let NERDTreeAutoDeleteBuffer = 1

"Make it prettier.
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1

"....................END..............
"write the file quick cmd.
nmap <Leader>s :write<Enter>
"quit quickly without writing.
nmap <Leader>q :q!<Enter>
"save and quit.
nmap <Leader>w :wq!<Enter>

"Remove highlight in search.
nmap <Leader>h :nohl<Enter>

"Open NERDTree quick.
nmap <Leader>n :NERDTree<Enter>

"Resize things straight forward.
nmap < <C-w>< 
nmap > <C-w>>
nmap + <C-w>+
nmap - <C-w>-

"Get templates by keyword & tab
imap html<Tab> <esc>:r /dotfiles/webtemp/html.html<Enter>12j8li

"Autocomplete for HTML (buitin)
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags

"......//////////////EMMET////////////////////
".........................................
"Map <C-y> to dt ok boss?
