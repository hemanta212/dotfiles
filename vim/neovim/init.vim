" Fisa-nvim-config
" http://nvim.fisadev.com
" version: 10.0

" TODO current problems:
" * end key not working undef tmux+fish

" ============================================================================
" Vim-plug initialization
" Avoid modify this section, unless you are very sure of what you are doing

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

" Obscure hacks done, you can now modify the rest of the .vimrc as you wish :)

" ============================================================================
" Active plugins
" You can disable or add new ones here:

" this needs to be here, so vim-plug knows we are declaring the plugins we
" want to use
call plug#begin('~/.config/nvim/plugged')

" Now the actual plugins:



" Better file browser
Plug 'scrooloose/nerdtree'

" Nerdtree tabs
Plug 'jistr/vim-nerdtree-tabs'

" Terminal Vim with 256 colors colorscheme
Plug 'fisadev/fisa-vim-colorscheme'

" Airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Code and files fuzzy finder
" Plug 'ctrlpvim/ctrlp.vim'
" Extension to ctrlp, for fuzzy command finder
" Plug 'fisadev/vim-ctrlp-cmdpalette'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'


" Async autocompletion
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"
" Completion from other opened files
Plug 'Shougo/context_filetype.vim'

" Python autocompletion
Plug 'zchee/deoplete-jedi', { 'do': ':UpdateRemotePlugins' }
"
" Just to add the python go-to-definition and similar features, autocompletion
" from this plugin is disabled
"Plug 'davidhalter/jedi-vim'

"Autocomplettion plugin by Neo.
"    Plug 'shougo/neocomplete.vim'
"

" Automatically sort python imports
Plug 'fisadev/vim-isort'

" Generate html in a simple way
Plug 'mattn/emmet-vim'

" Git integration
Plug 'tpope/vim-fugitive'


" Linters
Plug 'neomake/neomake'

"  
"TO search basically anything from vim.(Use it by ctrl + p.
    Plug 'kien/ctrlp.vim'
"

"Cheat.sh
Plug 'dbeniamine/cheat.sh-vim'
" TODO is it running on save? or when?
" TODO not detecting errors, just style, is it using pylint?

" Relative numbering of lines (0 is the current line)
" (disabled by default because is very intrusive and can't be easily toggled
" on/off. When the plugin is present, will always activate the relative
" numbering every time you go to normal mode. Author refuses to add a setting
" to avoid that)



" Tell vim-plug we finished declaring plugins, so it can load them
call plug#end()

" ============================================================================
" Install plugins the first time vim runs

if vim_plug_just_installed
    echo "Installing Bundles, please ignore key map error messages"
    :PlugInstall
endif

" ============================================================================
" Vim settings and mappings
" You can edit them as you wish

" tabs and spaces handling
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set guicursor=
" show line numbers
set nu

" remove ugly vertical lines on window division
set fillchars+=vert:\

" use 256 colors when possible
if (&term =~? 'mlterm\|xterm\|xterm-256\|screen-256') || has('nvim')
    let &t_Co = 256
    colorscheme fisa
else
    colorscheme delek
endif

" needed so deoplete can auto select the first suggestion
set completeopt+=noinsert
" comment this line to enable autocompletion preview window
" (displays documentation related to the selected completion option)
set completeopt-=preview

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

" clear search results
nnoremap <silent> // :noh<CR>

" clear empty spaces at the end of lines on save of python files
autocmd BufWritePre *.py :%s/\s\+$//e

" fix problems with uncommon shells (fish, xonsh) and plugins running commands
" (neomake, ...)
set shell=/bin/bash

" ============================================================================
" Plugins settings and mappings
" Edit them as you wish.

" Tagbar -----------------------------

" toggle tagbar display
map <F4> :TagbarToggle<CR>
" autofocus on tagbar open
let g:tagbar_autofocus = 1

" NERDTree -----------------------------

" toggle nerdtree display
map <F3> :NERDTreeToggle<CR>
" open nerdtree with the current file selected
nmap ,t :NERDTreeFind<CR>
" don;t show these file types
let NERDTreeIgnore = ['\.pyc$', '\.pyo$']

" Nerdtree TABS ------------------------------
let g:nerdtree_tabs_open_on_console_startup=1

" Tasklist ------------------------------

" show pending tasks list
map <F2> :TaskList<CR>

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
function! CtrlPWithSearchText(search_text, ctrlp_command_end)
    execute ':CtrlP' . a:ctrlp_command_end
    call feedkeys(a:search_text)
endfunction
" same as previous mappings, but calling with current word as default text
"nmap ,wg :call CtrlPWithSearchText(expand('<cword>'), 'BufTag')<CR>
"nmap ,wG :call CtrlPWithSearchText(expand('<cword>'), 'BufTagAll')<CR>
"nmap ,wf :call CtrlPWithSearchText(expand('<cword>'), 'Line')<CR>
"nmap ,we :call CtrlPWithSearchText(expand('<cword>'), '')<CR>
"nmap ,pe :call CtrlPWithSearchText(expand('<cfile>'), '')<CR>
"nmap ,wm :call CtrlPWithSearchText(expand('<cword>'), 'MRUFiles')<CR>
"nmap ,wc :call CtrlPWithSearchText(expand('<cword>'), 'CmdPalette')<CR>


" Deoplete -----------------------------

" Use deoplete.

let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_ignore_case = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#auto_complete=1
" complete with words from any opened file
let g:context_filetype#same_filetypes = {}
let g:context_filetype#same_filetypes._ = '_'

" Jedi-vim ------------------------------

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

"////////////////////////////////MY SETUP////////////////
"//////////////////////////////////////////////////////////////
"//////////////////////////////////////////////////////////////
" General Settings
"--------------------
"set bs=indent,eol,start	" allow backspacing over everything in insert mode
"set history=100		" keep 100 lines of command line history
"set ruler			" show the cursor position all the time
"set ar				" auto read when file is changed from outside
"set nu				" show line numbers
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
    
"set nowrap       "Don't wrap lines
"set linebreak    "Wrap lines at convenient points

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

let g:python3_host_prog = '~/.cache/pypoetry/virtualenvs/neovim3/bin/python3'

"run python file from <F6>.
"map <F5> <Esc>:w<CR>:!clear;python3 %<CR>
nnoremap <F5> :sp<CR> :term python3 % <CR> 

"Run python Script from vim using the f6 button in a new window.
"imap <F6> <Esc>:w<CR>:!clear;python3 %<CR>
"nmap <F6> <Esc>:w<CR>:!clear;python3 %<CR>

"save and run together
imap <Leader>b <Esc><Leader>s<F5>
nmap <Leader>b <Leader>s<F5>
nnoremap <Leader>bb :bd!<CR>




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

"......//////////////EMMET////////////////////
".........................................
"Map <C-y> to dt ok boss?
let g:user_emmet_leader_key='dt'
"
"......//////////////Relativ numbers////////////////////
".........................................

"map numbertoggle 
map <Leader>nu :NumbersToggle<Enter>

"map terminal esc
map <ESC> :<C-\><C-n>
map <Leader>t :sp term<CR>

"
"......//////////////i////////////////////

"/////////////////////////////////////////////////////////
".....................NEoplete vim ////////////////////
"....................................................
"Enabel neocomplete autocomplete feature by default.
"  let g:neocomplete#enable_at_startup = 1


"<TAB>: completion.
"inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
"<C-h>, <BS>: close popup and delete backword char.
" inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
" inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
" inoremap <expr><C-y>  neocomplete#close_popup()
" inoremap <expr><C-e>  neocomplete#cancel_popup()




"Manage the autopopping pydoc.
"If you prefer the Omni-Completion tip window to close when a selection is
"made, these lines close it on movement in insert mode or when leaving
"insert mode
"autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
"autocmd InsertLeave * if pumvisible() == 0|pclose|endif

"Write selected lines to python file

vnoremap <Leader>pw :w .temp.swp<CR>j
vnoremap <Leader>pa :w! >> .dump.swp<CR>
vmap <Leader>pi <Leader>pw<Leader>pddd<Leader>prw<Leader>pd

nnoremap <Leader>pra :read !python3 .dump.swp<CR><CR>
nnoremap <Leader>prw :read !python3 .temp.swp<CR> :!rm .temp.swp <CR><CR>
nnoremap <Leader>prd :!rm .dump.swp .temp.swp <CR><CR>

nnoremap <Leader>pd <C-{>o```python<Esc><C-}>o```<CR><CR><Esc>
nnoremap <Leader>cd <C-{>o```<Esc><C-}>o```<CR><CR><Esc>
nnoremap <Leader>dd dkdd{jdd}


"map" terminal esc
"tnoremap p <Leader>t :term<CR>
