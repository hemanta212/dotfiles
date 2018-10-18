"//////////////REAL ONE THAT I USE///////////
"IF you dont have a VIrutalenv set up and want to run in separate window
nnoremap <buffer> <Leader>p  :exec '!python3' shellescape(@%, 1)<Enter>

"IF you dont have a VIrutalenv set up and want to run in same window as of
"file
nnoremap <buffer> <Leader>pp :term python3 % <CR>

"IF you have virtual env and want to run 
"in separate window
nnoremap <buffer> <F6>  :exec '!pipenv run python' shellescape(@%, 1)<Enter>

"save and run together
imap <Leader>r <Esc><Leader>s<F6>
nmap <Leader>r <Leader>s<F6>

"IF you have virtual env and want to run 
"result in below your file not in separate window
nnoremap <F5> :term pipenv run python % <CR>

"save and run together
imap <Leader>b <Esc><Leader>s<F5>
nmap <Leader>b <Leader>s<F5> 

"OTHER OPTIONS As well
"run python file from <F6>.
"map <F6> <Esc>:w<CR>:!clear;python3 %<CR>

"Run python Script from vim using the f6 button in a new window.
"imap <F6> <Esc>:w<CR>:!clear;python3 %<CR>
"nmap <F6> <Esc>:w<CR>:!clear;python3 %<CR>

"run python file from <F6>.
"map <F5> <Esc>:w<CR>:!clear;python3 %<CR>

"Run python Script from vim using the f6 button in a new window.
"imap <F6> <Esc>:w<CR>:!clear;python3 %<CR>
"nmap <F6> <Esc>:w<CR>:!clear;python3 %<CR>


"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

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
nmap <Leader>s :write<Enter>
"quit quickly without writing.
nmap <Leader>q :q!<Enter>
"save and quit.
nmap <Leader>w :wq!<Enter>

"Remove highlight in search.
nmap <Leader>h :nohl<Enter>

" tab navigation mappings
map tp :tabp<CR>
map tm :tabm 
map tt :tabnew 
map td :tab split<CR>
map tn :tabn<CR>
map ts :vs<CR>
map tb :sp<CR>

"map numbertoggle 
map <Leader>nu :NumbersToggle<Enter>

"map terminal esc
tnoremap kj :<C-\><C-n>
map <Leader>t :term<CR>
