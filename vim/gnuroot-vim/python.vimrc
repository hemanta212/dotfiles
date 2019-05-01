"-------------------------------------
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
    \ set expandtab |
    \ set autoindent |
    \ set fileformat=unix

"Activate syntax highlight and make code pretty.
    let python_highlight_all=1
    syntax on

"Enabel neocomplete autocomplete feature by default.
"ACTIVE SETTIGN IN PLUGINGS THESE ARE JUST FOR TIP OR REFERENCE
"let g:neocomplete#enable_at_startup = 1
"let g:deoplete#enable_at_startup = 1

"enable youcomplete at startup.(!!only use one bet neocomplete and
"youcompleteme ok boss?>)
"let g:#enable_at_startup = 1
"let g:ycm_autoclose_preview_window_after_completion=1
"map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

"python with virtualenv support
"????????????OUTDATED BUT USEFUL IF YOU STILL USE VIRUALENV INSTEAD OF PIPENV
            " OH and it didnt work for me for some reason 
"py3 << EOF
"import os
"import sys
"if 'VIRTUAL_ENV' in os.environ:
"  project_base_dir = os.environ['VIRTUAL_ENV']
"  activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
"  execfile(activate_this, dict(__file__=activate_this))
"EOF


"Flagging Unnecessary Whitespace
highlight BadWhitespace ctermbg=red guibg=darkred
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/



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


"TIP ON HOW PYTHON FILES ARE RUN 
"!!!!!!!!!!SETTINGS ARE IN key.vimrc FILE!!!!!!

"IF you dont have a VIrutalenv set up and want to run in separate window
"nnoremap <buffer> <Leader>p  :exec '!python3' shellescape(@%, 1)<Enter>

"IF you dont have a VIrutalenv set up and want to run in same window as of
"file

"nnoremap <buffer> <Leader>pp :term python3 % <CR>

"IF you have virtual env and want to run 
"in separate window

"nnoremap <buffer> <F6>  :exec '!pipenv run python' shellescape(@%, 1)<Enter>

"save and run together

"imap <Leader>r <Esc><Leader>s<F6>
"nmap <Leader>r <Leader>s<F6>

"IF you have virtual env and want to run 
"result in below your file not in separate window

"nnoremap <F5> :term pipenv run python % <CR>

"save and run together

"imap <Leader>b <Esc><Leader>s<F5>
"nmap <Leader>b <Leader>s<F5> 




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



