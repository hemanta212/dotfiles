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

" Now the actual plugins:

" Better file browser
Plug 'scrooloose/nerdtree'

" Nerdtree tabs
"Plug 'jistr/vim-nerdtree-tabs'

" Terminal Vim with 256 colors colorscheme
Plug 'fisadev/fisa-vim-colorscheme'

" Airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Extension to ctrlp, for fuzzy command finder
" Plug 'fisadev/vim-ctrlp-cmdpalette'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Completion from other opened files
Plug 'Shougo/context_filetype.vim'

" Linters
Plug 'neomake/neomake'

" Python formatting
Plug 'psf/black'

Plug 'vim-vdebug/vdebug'

" Automatically sort python imports
Plug 'fisadev/vim-isort'

" Generate html in a simple way
Plug 'mattn/emmet-vim'

" Git integration
Plug 'tpope/vim-fugitive'

"TO search basically anything from vim.(Use it by ctrl + p.
Plug 'kien/ctrlp.vim'

" Navigate between vim and tmux
Plug 'christoomey/vim-tmux-navigator'
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'tmux-plugins/vim-tmux'

"Cheat.sh
Plug 'dbeniamine/cheat.sh-vim'

" Backup vim session
Plug 'tpope/vim-obsession'

" Backup vim session
Plug 'kassio/neoterm'

"Dart/Flutter vim
Plug 'dart-lang/dart-vim-plugin'

" Dart autocomplete By lsp
Plug 'natebosch/vim-lsc'
Plug 'natebosch/vim-lsc-dart'


" Dart autocomplete By cocnvim (Performance intensive)
"Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Deoplete vim
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

" TODO is it running on save? or when?
" TODO not detecting errors, just style, is it using pylint?

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
"set completeopt-=preview

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

" Nerdtree TABS ------------------------------
let g:nerdtree_tabs_open_on_console_startup=1


" Neomake ------------------------------
" Run linter on write
autocmd! BufWritePost * Neomake
autocmd BufWritePre *.py execute ':Black'

" Check code as python3 by default
let g:neomake_python_python_maker = neomake#makers#ft#python#python()
let g:neomake_python_pylint_maker = neomake#makers#ft#python#pylint()
let g:neomake_python_python_maker.exe = 'python -m py_compile'
let g:neomake_python_pylint_maker.exe = 'pylint'



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
nmap ,wg :call CtrlPWithSearchText(expand('<cword>'), 'BufTag')<CR>
nmap ,wG :call CtrlPWithSearchText(expand('<cword>'), 'BufTagAll')<CR>
nmap ,wf :call CtrlPWithSearchText(expand('<cword>'), 'Line')<CR>
nmap ,we :call CtrlPWithSearchText(expand('<cword>'), '')<CR>
nmap ,pe :call CtrlPWithSearchText(expand('<cfile>'), '')<CR>
nmap ,wm :call CtrlPWithSearchText(expand('<cword>'), 'MRUFiles')<CR>
nmap ,wc :call CtrlPWithSearchText(expand('<cword>'), 'CmdPalette')<CR>


" Deoplete -----------------------------
let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_ignore_case = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#auto_complete=1

"" complete with words from any opened file
let g:context_filetype#same_filetypes = {}
let g:context_filetype#same_filetypes._ = '_'


" Jedi-vim ------------------------------
" Disable autocompletion (using deoplete instead)
let g:jedi#completions_enabled = 0

" Go to definition
let g:jedi#goto_command = ',d'
nmap ,d :vs<CR>:call jedi#goto()<CR>

" Find ocurrences
let g:jedi#usages_command = ',o'
" Find assignments
let g:jedi#goto_assignments_command = ',a'
" Go to definition in new tab
nmap ,D :tab split<CR>:call jedi#goto()<CR>


" Airline ------------------------------
"let g:airline#extensions#tabline#enabled = 0
" Watch out for performance issue in powerline fonts
" let g:airline_powerline_fonts = 1 

let g:airline_theme = 'minimalist'
"let g:airline#extensions#whitespace#enabled = 0

" to use fancy symbols for airline, uncomment the following lines and use a
" patched font (more info on docs/fancy_symbols.rst)
"if !exists('g:airline_symbols')
"   let g:airline_symbols = {}
"endif
"let g:airline_left_sep = '⮀'
"let g:airline_left_alt_sep = '⮁'
"let g:airline_right_sep = '⮂'
"let g:airline_right_alt_sep = '⮃'
"let g:airline_symbols.branch = '⭠'
"let g:airline_symbols.readonly = '⭤'
"let g:airline_symbols.linenr = '⭡'


"-------NERDTree by scroollose.-------
" toggle nerdtree display
map <F3> :NERDTreeToggle<CR>

" open nerdtree with the current file selected
nmap ,t :NERDTreeFind<CR>

" don;t show these file types
let NERDTreeIgnore = ['\.pyc$', '\.pyo$']

"Open directly to curently working file by \v
nnoremap <silent> <Leader>v :NERDTreeFind<CR>

"close after selecting one file to open.
let NERDTreeQuitOnOpen = 1

"Delete the buffer of file you delleted.
let NERDTreeAutoDeleteBuffer = 1

"Make it prettier.
"DTreeMinimalUI = 1
let NERDTreeDirArrows = 1

"Open NERDTree quick.
nmap <Leader>n :NERDTree<Enter>

"start nerdtree automatucally if no file js specjfisd or dir is opened.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif


"......//////////////EMMET////////////////////
"Map <C-y> to dt ok boss?
let g:user_emmet_leader_key='dt'



"/////////////VIM_LSC//////////////////////
"Enable/disble VIM_LSC itself.
"noremap <buffer> <leader>lscd :LSClientDisable<cr>
"noremap <buffer> <leader>lsce :LSClientEnable<cr>
"noremap <buffer> <leader>lscr :LSClientRestartServer<cr>

" Enable/diasble autocomplete
let g:lsc_enable_autocomplete = v:true

" Use all the defaults (recommended):
"let g:lsc_auto_map = v:true

" Apply the defaults with a few overrides:
"let g:lsc_auto_map = {'defaults': v:true, 'FindReferences': '<leader>r'}
"
" Setting a value to a blank string leaves that command unmapped:
"let g:lsc_auto_map = {'defaults': v:true, 'FindImplementations': ''}

" ... or set only the commands you want mapped without defaults.
" Complete default mappings are:

"    \ 'GoToDefinition': '<C-]>',
"    \ 'GoToDefinitionSplit': ['<C-W>]', '<C-W><C-]>'],
"    \ 'NextReference': '<C-n>',
"    \ 'PreviousReference': <C-p>',
"    \ 'FindImplementations': 'gI',
"    \ 'FindCodeActions': 'ga',
"    \ 'Completion': 'completefunc',
let g:lsc_auto_map = {
    \ 'GoToDefinition': 'gd',
    \ 'GoToDefinitionSplit': ['gsd', 'gsdv'],
    \ 'FindReferences': 'gr',
    \ 'NextReference': '<leader>ln',
    \ 'PreviousReference': '<leader>lp',
    \ 'FindImplementations': 'gi',
    \ 'FindCodeActions': '<leader>ca',
    \ 'Rename': 'gR',
    \ 'ShowHover': v:true,
    \ 'DocumentSymbol': 'go',
    \ 'WorkspaceSymbol': 'gS',
    \ 'SignatureHelp': 'gm',
    \ 'Completion': 'completefunc',
    \}

"Configure the dir of split in showHover (using K)
"let g:lsc_preview_split_direction = 'below' or 'above'

" Auto close the documentation window on completion
autocmd CompleteDone * silent! pclose

" complete by using tab
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" : "\t"

inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

command! -nargs=0 Format :DartFmt

"/////////////VIM_LSC_DART//////////////////////
noremap <buffer> <leader>tr :DartToggleMethodBodyType<cr>
nnoremap <silent> <space>a  ::LSClientAllDiagnostics<cr>



"////////////////////////////////MY SETUP////////////////
"
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
nmap <Leader>s :write<Enter> :Format<Enter>
"quit quickly without writing.
nmap <Leader>q :q!<Enter>
"save and quit.
nmap <Leader>w :wq!<Enter>

"Remove highlight in search.
nmap <Leader>h :nohl<Enter>

let g:python3_host_prog = '~/.virtualenvs/neovim3/bin/python3'

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
nnoremap <Leader>t :sp \| term<CR>
tnoremap kj <C-\><C-n>


"'''''''''''/////////////////// COC.NVIM configs//////////////
" Remap keys for gotos
"nmap <silent> gd <Plug>(coc-definition)
"nmap <silent> gy <Plug>(coc-type-definition)
"nmap <silent> gi <Plug>(coc-implementation)
"nmap <silent> gr <Plug>(coc-references)
"
"" if hidden is not set, TextEdit might fail.
set hidden
"
"" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup
"
"" Better display for messages
set cmdheight=2
"
"" You will have bad experience for diagnostic messages when it's default "4000.
set updatetime=300
"
"" don't give |ins-completion-menu| messages.
set shortmess+=c
"
"" always show signcolumns
set signcolumn=yes
"
"" Use tab for trigger completion with characters ahead and navigate.
"" Use command ':verbose imap <tab>' to make sure tab is not mapped by oth"er plugin.
"inoremap <silent><expr> <TAB>
"      \ pumvisible() ? "\<C-n>" :
"      \ <SID>check_back_space() ? "\<TAB>" :
"      \ coc#refresh()
"inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
"
"function! s:check_back_space() abort
"  let col = col('.') - 1
"  return !col || getline('.')[col - 1]  =~# '\s'
"endfunction
"
"" Use <c-space> to trigger completion.
"inoremap <silent><expr> <c-space> coc#refresh()
"
"" Use <cr> to confirm completion, `<C-g>u` means break undo chain at curr"ent position.
"" Coc only does snippet and additional edit on confirm.
"inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
"" Or use `complete_info` if your vim support it, like:
"" inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : ""\<C-g>u\<CR>"
"
"" Use `[g` and `]g` to navigate diagnostics
"nmap <silent> [g <Plug>(coc-diagnostic-prev)
"nmap <silent> ]g <Plug>(coc-diagnostic-next)
"
"" Use K to show documentation in preview window
"nnoremap <silent> K :call <SID>show_documentation()<CR>
"
"function! s:show_documentation()
"  if (index(['vim','help'], &filetype) >= 0)
"    execute 'h '.expand('<cword>')
"  else
"    call CocAction('doHover')
"  endif
"endfunction
"
"" Highlight symbol under cursor on CursorHold
"autocmd CursorHold * silent call CocActionAsync('highlight')
"
"" Remap for rename current word
"nmap <leader>rn <Plug>(coc-rename)
"
"" Remap for format selected region
"xmap <leader>f  <Plug>(coc-format-selected)
"nmap <leader>f  <Plug>(coc-format-selected)
"
"augroup mygroup
"  autocmd!
"  " Setup formatexpr specified filetype(s).
"  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelec"ted')
"  " Update signature help on jump placeholder
"  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp'")
"augroup end
"
"" Remap for do codeAction of selected region, ex: `<leader>aap` for curre"nt paragraph
"xmap <leader>a  <Plug>(coc-codeaction-selected)
"nmap <leader>a  <Plug>(coc-codeaction-selected)
"
"" Remap for do codeAction of current line
"nmap <leader>ca  <Plug>(coc-codeaction)
"" Fix autofix problem of current line
"nmap <leader>qf  <Plug>(coc-fix-current)
"
"" Create mappings for function text object, requires document symbols fea"ture of languageserver.
"xmap if <Plug>(coc-funcobj-i)
"xmap af <Plug>(coc-funcobj-a)
"omap if <Plug>(coc-funcobj-i)
"omap af <Plug>(coc-funcobj-a)
"
"" Use <TAB> for select selections ranges, needs server support, like: coc"-tsserver, coc-python
"nmap <silent> <TAB> <Plug>(coc-range-select)
"xmap <silent> <TAB> <Plug>(coc-range-select)
"
"" Use `:Format` to format current buffer
"command! -nargs=0 Format :call CocAction('format')
"
"" Use `:Fold` to fold current buffer
"command! -nargs=? Fold :call     CocAction('fold', <f-args>)
"
"" use `:OR` for organize import of current buffer
"command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.o"rganizeImport')
"
"" Add status line support, for integration with other plugin, checkout `:"h coc-status`
"
"" Using CocList
"" Show all diagnostics
"nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
"" Manage extensions
"nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
"" Show commands
"nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
"" Find symbol of current document
"nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
"" Search workspace symbols
"nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
"" Do default action for next item.
"nnoremap <silent> <space>j  :<C-u>CocNext<CR>
"" Do default action for previous item.
"nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
"" Resume latest coc list
"nnoremap <silent> <space>p  :<C-u>CocListResume<CR>


""//////////////////////COC VIM AIRLINE STATUS INTEGRATION TIPS

""Disable\Enable vim-airline integration:
"let g:airline#extensions#coc#enabled = 1
""Change error symbol:
"let airline#extensions#coc#error_symbol = 'Error:'
""Change warning symbol:
"let airline#extensions#coc#warning_symbol = 'Warning:'
""Change error format:
"let airline#extensions#coc#stl_format_err = '%E{[%e(#%fe)]}'
""Change warning format:
"let airline#extensions#coc#stl_format_warn = '%W{[%w(#%fw)]}'

"" /////////////////// SOME STATUS LINE MAGIC //////////////////
"function! StatusDiagnostic() abort
"  let info = get(b:, 'coc_diagnostic_info', {})
"  if empty(info) | return '' | endif
"	  let msgs = []
"	  if get(info, 'error', 0)
"	    call add(msgs, 'E' . info['error'])
"	  endif
"	  if get(info, 'warning', 0)
"	    call add(msgs, 'W' . info['warning'])
"	  endif
"	return join(msgs, ' ') . ' ' . get(g:, 'coc_status', '')
"endfunction
"
"set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}%{Stat"usDiagnostic()}
"
"
""'''''''''''/////////////////// Flutter coc-flutter //////////////
"nnoremap <Leader>fpg :CocCommand flutter.pub.get<CR>
"nnoremap <Leader>fr :CocCommand flutter.run<CR>
"
"nnoremap <Leader>fg :CocCommand flutter.gotoSuper<CR>
"
"
""'''''''''''/////////////////// Python coc-python //////////////
"nnoremap <Leader>pi :CocCommand python.setInterpreter<CR>
"nnoremap <Leader>pe :CocCommand python.execInTerminal<CR>
"nnoremap <Leader>pr :CocCommand python.startREPL<CR>

