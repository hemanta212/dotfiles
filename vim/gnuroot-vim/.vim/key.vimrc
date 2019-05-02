"//////////////REAL ONE THAT I USE///////////
"IF you dont have a VIrutalenv set up and want to run in separate window
"nnoremap <buffer> <Leader>p  :exec '!python3' shellescape(@%, 1)<Enter>

"IF you dont have a VIrutalenv set up and want to run in same window as of
"file
"nnoremap <buffer> <Leader>pp :term python3 % <CR>

"IF you have virtual env and want to run 
"in separate window
"nnoremap <buffer> <F6>  :exec '!python3' shellescape(@%, 1)<Enter>
"nnoremap <buffer> <F6>  :exec '!pipenv run python' shellescape(@%, 1)<Enter>

"save and run together
"imap <Leader>r <Esc><Leader>s<F6>
"nmap <Leader>r <Leader>s<F6>

"IF you have virtual env and want to run 
"result in below your file not in separate window
"nnoremap <F5> :term python3 % <CR>
"nnoremap <F5> :term pipenv run python % <CR>

"save and run together
"imap <Leader>b <Esc><Leader>s<F5>
"nmap <Leader>b <Leader>s<F5> 

"run python file from <F6>.
map <Leader>r <Esc>:w<CR>:!clear;python3 %<CR>
"nnoremap <buffer> <Leader>r :exec '!python3' shellescape(@%, 1)<Enter>
"Run python Script from vim using the f6 button in a new window.
"imap <F6> <Esc>:w<CR>:!clear;python3 %<CR>
"nmap <F6> <Esc>:w<CR>:!clear;python3 %<CR>

"save and run together
imap <F6> <Esc><Leader>s<Leader>r
nmap <F6> <Leader>s<Leader>r


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
map ts :vs 
map tb :sp 


"map numbertoggle 
map <Leader>nu :NumbersToggle<Enter>
map <Leader>dt :r !python3 ~/.personal/.time.py date<Enter>o<esc><Leader>dtt
map <Leader>dtt :r !python3 ~/.personal/.time.py time<Enter>^i<tab><tab><esc>o<esc>o<tab><tab>
map <Leader>ip vip<C-v><S-i><tab><esc> 
map <Leader>uip vip< 

map <Leader>cp vip<C-v><S-i>#<esc> 
map <Leader>cl ^i# <esc>
map <Leader>cs <C-v><S-i># <esc>
map <Leader>dp <S-[>i'''<esc><S-]>i'''<esc>2<C-o>
map <Leader>ds <S-i>i'''<esc><C-o>i'''<esc><C-o>

map <Leader>ucs <C-v>x<esc>
"map terminal esc
"tnoremap kj :<C-\><C-n>
"map <Leader>t :term<CR>