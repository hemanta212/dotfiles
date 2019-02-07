"////////---------/////////////-----------------///////////////
".....................................................................
"--------------------
" General Settings
"--------------------
set bs=indent,eol,start	" allow backspacing over everything in insert mode
set history=100		" keep 100 lines of command line history
set ruler			" show the cursor position all the time
set ar				" auto read when file is changed from outside
set nu				" show line numbers
syntax on			" syntax highlight
set hlsearch		" search highlighting
set clipboard=unnamed	" yank to the system register (*) by default
set showmatch		" Cursor shows matching ) and }
set showmode		" Show current mode
"set background=dark
"Telling vim where to split the screen when called :vs and :sp.
set splitbelow
set splitright
set t_Co=256
set encoding=utf-8

"Tabs to spaces *tab insert spaces*
set expandtab
set ts=2


"Enable folding
set foldmethod=indent
set foldlevel=99

" Enable folding with the spacebar
"nnoremap <space> za
"NOTE:THis folding may be bad use custom folding for your programming language
"like simplyfold plugin for python.
"automatically change dir to current file
autocmd BufEnter * silent! lcd %:p:h

" autocompletion of files and commands behaves like shell
" (complete only the common part, list the options that match)
set wildmode=list:longest

" save as sudo
ca w!! w !sudo tee "%"
 
" when scrolling, keep cursor 3 lines away from screen border
set scrolloff=3

set nowrap       "Don't wrap lines
set linebreak    "Wrap lines at convenient points


