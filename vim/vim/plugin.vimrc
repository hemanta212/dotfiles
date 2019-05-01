"Reload while editing it
autocmd! bufwritepost plugin.vimrc source ~/.vimrc



".............NERDTree Setup...............

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


".....................NEoplete vim ////////////////////

"<TAB>: completion.
"inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
"<C-h>, <BS>: close popup and delete backword char.
" inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
" inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
" inoremap <expr><C-y>  neocomplete#close_popup()
" inoremap <expr><C-e>  neocomplete#cancel_popup()

"Enabel neocomplete autocomplete feature by default.
"let g:neocomplete#enable_at_startup = 1



".....................Deoplete vim ////////////////////

let g:deoplete#enable_at_startup = 1


"///////////////////////////////////////////////////////////////
"....................Powerline .....................
"/////////////////////////////////////////

"Setup powerline in vim. first install powerline by pip install
 "powerline-status and do pip show powerline-status to get its path.
"replace the path below by that path shown by pip.
"To use powerline inside the vim editor.
"set rtp+=/home/hs/.local/lib/python3.6/site-packages/powerline/bindings/vim/
"set laststatus=2
"set t_Co=256

"......//////////////EMMET////////////////////
".........................................
"Map <C-y> to dt ok boss?
let g:user_emmet_leader_key='dt'



" Neomake ------------------------------

" Run linter on write
"autocmd! BufWritePost * Neomake

" Check code as python3 by default
"let g:neomake_python_python_maker = neomake#makers#ft#python#python()
""let g:neomake_python_flake8_maker = neomake#makers#ft#python#flake8()
"let g:neomake_python_python_maker.exe = 'python3 -m py_compile'
"let g:neomake_python_flake8_maker.exe = 'python3 -m flake8'


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

" ////////////////////// AIRLINE ///////////////////////////
" ////////////////////////////////////////////////////////

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

"" Jedivim ------------------------------

" Disable autocompletion (using deoplete instead)
"let g:jedi#completions_enabled = 0

" All these mappings work only for python code:
" Go to definition
"let g:jedi#goto_command = ',d'
"nmap ,d :vs<CR>:call jedi#goto()<CR>

" Find ocurrences
"let g:jedi#usages_command = ',o'
" Find assignments
"let g:jedi#goto_assignments_command = ',a'
" Go to definition in new tab
"nmap ,D :tab split<CR>:call jedi#goto()<CR>

