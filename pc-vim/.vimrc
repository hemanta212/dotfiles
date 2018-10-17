set nocompatible              " required
filetype off                  " required

" set the runtime path to include Vundle and initialize to intall vundle first do git clone ht"tps://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim in the terminal.
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
"//////////////////..............//////////////...........
"!!!!!!!!!!!!------------------11!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"After copying this vimrc goto terminal and type git clone
"https://github.com/gmarik/vundle.vim.git ~/.vim/bundle/Vundle.vim
"Then open vim and type :PluginInstall. To set up all plugins!!!
"-------------------------------------------------!!!!!!!!!!!!?////////////////
"////////////////.........../
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" add all your plugins here (note older versions of Vundle
" used Bundle instead of Plugin)

"PLUGINS LIST:
"plugin related to folding (from realpython.1st addition.)
    Plugin 'tmhedberg/SimpylFold'
"plugin for autoidentation in python.
    Plugin 'vim-scripts/indentpython.vim'
"
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
"PEP-8 checking syntax plugin.
    Plugin 'nvie/vim-flake8'
"Autocomplettion plugin by Neo.
    Plugin 'shougo/neocomplete.vim'
"Autocomplete by Valloric. Use one bet neo and valloric's.
"	  Plugin 'Valloric/YouCompleteMe'
"plugin for theme Zenburn for CLI and another for GUI.(its logic is below).
    Plugin 'jnurmine/Zenburn'
    Plugin 'altercation/vim-colors-solarized'
"emmet plugin for html css and js etc
    Plugin 'mattn/emmet-vim'
"Enable the powerline (basic file info at buttom. (  :) My dream!!)
"   Plugin 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
"plugin for cheat.sh
    Plugin 'dbeniamine/cheat.sh-vim'

" Terminal Vim with 256 colors colorscheme
Plugin 'fisadev/fisa-vim-colorscheme'

" Linters
Plugin 'neomake/neomake'

" Plug 'fisadev/vim-ctrlp-cmdpalette'
Plugin 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plugin 'junegunn/fzf.vim'

" Airline
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

Plugin 'Shougo/context_filetype.vim'
" Python autocompletion
Plugin 'zchee/deoplete-jedi', { 'do': ':UpdateRemotePlugins' }
" Just to add the python go-to-definition and similar features, autocompletion
" from this plugin is disabled
Plugin 'davidhalter/jedi-vim'





" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
"--------------------
"
"////////---------/////////////-----------------///////////////
".....................................................................
"/////////////////SIMPLE PYTHON SETUP WITHOUT PLUGINS.////////////////////////
"" enable syntax highlighting
" syntax enable
"
"" show line numbers
" set number
"
"" set tabs to have 4 spaces
" set ts=4
"
"" indent when moving to the next line while writing code
"set autoindent
"
"" expand tabs into spaces
"set expandtab
"
"" when using the >> or << commands, shift lines by 4 spaces
"set shiftwidth=4
"
"" show a visual line under the cursor's current line
"set cursorline
"
"" show the matching part of the pair for [] {} and ()
"set showmatch
"
"" enable all Python syntax highlighting features
"let python_highlight_all = 1
"




""-------------------------------------
"".......//////Python Programming//......
"--------------------------------------

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
    \ set tabstop=2|
    \ set softtabstop=2|
    \ set shiftwidth=2|

"Activate syntax highlight and make code pretty.
    let python_highlight_all=1
    syntax on

"Enabel neocomplete autocomplete feature by default.
   let g:neocomplete#enable_at_startup = 1

"enable youcomplete at startup.(!!only use one bet neocomplete and
"youcompleteme ok boss?>)
"let g:#enable_at_startup = 1
"let g:ycm_autoclose_preview_window_after_completion=1
"map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

"python with virtualenv support
py3 << EOF
import os
import sys
if 'VIRTUAL_ENV' in os.environ:
  project_base_dir = os.environ['VIRTUAL_ENV']
  activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
  execfile(activate_this, dict(__file__=activate_this))
EOF



"Manage custom folding for python using simply fold.
"installing simply fold will automatically override vim default foldign
"written above but if you want to show docstring use.
let g:SimpylFold_docstring_preview=1

"Manage the autopopping pydoc.
"If you prefer the Omni-Completion tip window to close when a selection is
"made, these lines close it on movement in insert mode or when leaving
"insert mode
autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
autocmd InsertLeave * if pumvisible() == 0|pclose|endif


"run python file from <F6>.
"map <F6> <Esc>:w<CR>:!clear;python3 %<CR>
nnoremap <buffer> <Leader>r :exec '!python3' shellescape(@%, 1)<Enter>
"Run python Script from vim using the f6 button in a new window.
"imap <F6> <Esc>:w<CR>:!clear;python3 %<CR>
"nmap <F6> <Esc>:w<CR>:!clear;python3 %<CR>

"save and run together
imap <F5> <Esc><Leader>s<Leader>r
nmap <F5> <Leader>s<Leader>r


"run python file from <F6>.
"map <F5> <Esc>:w<CR>:!clear;python3 %<CR>
nnoremap <F5> :sp<CR> :term python3 % <CR> 

"Run python Script from vim using the f6 button in a new window.
"imap <F6> <Esc>:w<CR>:!clear;python3 %<CR>
"nmap <F6> <Esc>:w<CR>:!clear;python3 %<CR>

"save and run together
imap <Leader>b <Esc><Leader>s<F5>
nmap <Leader>b <Leader>s<F5>



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
" auto reload vimrc when editing it
autocmd! bufwritepost .vimrc source ~/.vimrc

"auto reload file.

syntax on			" syntax highlight
set hlsearch		" search highlighting
set clipboard=unnamed	" yank to the system register (*) by default
set showmatch		" Cursor shows matching ) and }
set showmode		" Show current mode

"Telling vim where to split the screen when called :vs and :sp.
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
"nnoremap <space> za
"NOTE:THis folding may be bad use custom folding for your programming language
"like simplyfold plugin for python.


"Flagging Unnecessary Whitespace
highlight BadWhitespace ctermbg=red guibg=darkred
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

"Add utf-8 support default.
set encoding=utf-8

"Resize things straight forward.
nmap < <C-w><
nmap > <C-w>>
nmap + <C-w>+
nmap - <C-w>-
"Tabs to spaces *tab insert spaces*
set expandtab
set ts=2
"Remap esc to kj
imap kj <esc>
cnoremap kj <esc>
nmap kj <esc>

set nowrap       "Don't wrap lines
set linebreak    "Wrap lines at convenient points

" Move normally between wrapped lines
nmap j gj
nmap k gk

"write the file quick cmd.
nmap <Leader>s :write<Enter>
"quit quickly without writing.
nmap <Leader>q :q!<Enter>
"save and quit.
nmap <Leader>w :wq!<Enter>

"Remove highlight in search.
nmap <Leader>h :nohl<Enter>

" autocompletion of files and commands behaves like shell
" (complete only the common part, list the options that match)
set wildmode=list:longest

" save as sudo
ca w!! w !sudo tee "%"
 
" tab navigation mappings
map tp :tabp<CR>
map tm :tabm 
map tt :tabnew 
map td :tab split<CR>
map tn :tabn<CR>
map ts :vs<CR>
map tb :sp<CR>


" when scrolling, keep cursor 3 lines away from screen border
set scrolloff=3


"map numbertoggle 
map <Leader>nu :NumbersToggle<Enter>

"map terminal esc
nnoremap kj :<C-\><C-n>
map <Leader>t :term<CR>



"...///////.....////////........////
".........Graphics................
"..///////.......//////.//////./////

" use 256 colors when possible
if (&term =~? 'mlterm\|xterm\|xterm-256\|screen-256') || has('nvim')
    let &t_Co = 256
    colorscheme fisa
else
    colorscheme delek
endif



"1. terminal color settings
"if has("gui_running")	" GUI color and font settings
"	set guifont=Courier:h18
"	set background=dark
"	set t_Co=256		" 256 color mode
"	set cursorline	" highlight current line
"	highlight CursorLine  guibg=#003853 ctermbg=24  gui=none cterm=none
"	colors moria
"else
"	colors evening
"endif

"..........OR..........
"Choose which theme to use with logic.
"    if has('gui_running')
"       set background=dark
"       colorscheme solarized
"    else
"       colorscheme zenburn
"    endif
"switching bet black and white solarized theme bg with f5..
"    call togglebg#map("<F5>")

"2. Built in Status bar(if powerline is not good for you.)
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


"......OTHER SETUPS of Plugin.......
"------------------------------

"...............................
"-------NERDTree by scroollose.-------
"////////////////////////////////////
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
"DTreeMinimalUI = 1
let NERDTreeDirArrows = 1

"Open NERDTree quick.
nmap <Leader>n :NERDTree<Enter>


"Hide .pyc file in nerdtree.
    let NERDTreeIgnore=['\.pyc$', '\~$'] "ignore files in NERDTree

"start nerdtree automatucally if no file js specjfisd or dir is opened.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif

"


"/////////////////////////////////////////////////////////
".....................NEoplete vim ////////////////////
"....................................................

"<TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
"<C-h>, <BS>: close popup and delete backword char.
 inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
 inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
 inoremap <expr><C-y>  neocomplete#close_popup()
 inoremap <expr><C-e>  neocomplete#cancel_popup()

"///////////////////////////////////////////////////////////////
"....................Powerline .....................
"/////////////////////////////////////////
"Setup powerline in vim. first install powerline by pip install
 "powerline-status and do pip show powerline-status to get its path.
"replace the path below by that path shown by pip.
"To use powerline inside the vim editor.
"    set  rtp+=/usr/local/lib/python3.4/dist-packages/powerline/bindings/vim/
"    set laststatus=2
"    set t_Co=256


"......//////////////EMMET////////////////////
".........................................
"Map <C-y> to dt ok boss?
let g:user_emmet_leader_key='dt'


"Get templates by keyword & tab
imap html<Tab> <esc>:r /dotfiles/webtemp/html.html<Enter>12j8li


" Neomake ------------------------------

" Run linter on write
autocmd! BufWritePost * Neomake

" Check code as python3 by default
let g:neomake_python_python_maker = neomake#makers#ft#python#python()
let g:neomake_python_flake8_maker = neomake#makers#ft#python#flake8()
let g:neomake_python_python_maker.exe = 'python3 -m py_compile'
let g:neomake_python_flake8_maker.exe = 'python3 -m flake8'

" Fzf ------------------------------

" file finder mapping
nmap ,e :Files<CR>
" tags (symbols) in current file finder mapping
nmap ,g :BTag<CR>
" tags (symbols) in all files finder mapping
nmap ,G :Tag<CR>
" general code finder in current file mapping
nmap ,f :BLines<CR>
" general code finder in all files mapping
nmap ,F :Lines<CR>
" commands finder mapping
nmap ,c :Commands<CR>
" to be able to call CtrlP with default search text
"function! CtrlPWithSearchText(search_text, ctrlp_command_end)
    "execute ':CtrlP' . a:ctrlp_command_end
    "call feedkeys(a:search_text)
"endfunction
" same as previous mappings, but calling with current word as default text
"nmap ,wg :call CtrlPWithSearchText(expand('<cword>'), 'BufTag')<CR>
"nmap ,wG :call CtrlPWithSearchText(expand('<cword>'), 'BufTagAll')<CR>
"nmap ,wf :call CtrlPWithSearchText(expand('<cword>'), 'Line')<CR>
"nmap ,we :call CtrlPWithSearchText(expand('<cword>'), '')<CR>
"nmap ,pe :call CtrlPWithSearchText(expand('<cfile>'), '')<CR>
"nmap ,wm :call CtrlPWithSearchText(expand('<cword>'), 'MRUFiles')<CR>
"nmap ,wc :call CtrlPWithSearchText(expand('<cword>'), 'CmdPalette')<CR>

" Airline ------------------------------

let g:airline_powerline_fonts = 0
let g:airline_theme = 'bubblegum'
let g:airline#extensions#whitespace#enabled = 0

" to use fancy symbols for airline, uncomment the following lines and use a
" patched font (more info on docs/fancy_symbols.rst)
if !exists('g:airline_symbols')
   let g:airline_symbols = {}
endif
let g:airline_left_sep = '⮀'
let g:airline_left_alt_sep = '⮁'
let g:airline_right_sep = '⮂'
let g:airline_right_alt_sep = '⮃'
let g:airline_symbols.branch = '⭠'
let g:airline_symbols.readonly = '⭤'
let g:airline_symbols.linenr = '⭡'

"" Jedi-vim ------------------------------

" Disable autocompletion (using deoplete instead)
let g:jedi#completions_enabled = 0

" All these mappings work only for python code:
" Go to definition
"let g:jedi#goto_command = ',d'
nmap ,d :vs<CR>:call jedi#goto()<CR>

" Find ocurrences
let g:jedi#usages_command = ',o'
" Find assignments
let g:jedi#goto_assignments_command = ',a'
" Go to definition in new tab
nmap ,D :tab split<CR>:call jedi#goto()<CR>




"....................END..............
"///////////////////////////////////
"LASTLY >>>>>>>>>
"Add this to ~/.inputrc to use vim in shell.
"set editing-mode vi

