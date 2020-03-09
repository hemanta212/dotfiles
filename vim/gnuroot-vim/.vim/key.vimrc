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
nnoremap <Leader>r <Esc>:w<CR>:!clear;python3 %<CR>
"nnoremap <buffer> <Leader>r :exec '!python3' shellescape(@%, 1)<Enter>
"Run python Script from vim using the f6 button in a new window.
"imap <F6> <Esc>:w<CR>:!clear;python3 %<CR>
"nmap <F6> <Esc>:w<CR>:!clear;python3 %<CR>

"save and run together
inoremap <F6> <Esc><Leader>s<Leader>r
nnoremap <F6> <Leader>s<Leader>r


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
nnoremap < <C-w><
nnoremap > <C-w>>
nnoremap + <C-w>+
nnoremap - <C-w>-

"Remap esc to kj
inoremap kj <esc>
cnoremap kj <esc>
nnoremap kj <esc>

" Move normally between wrapped lines
nnoremap j gj
nnoremap k gk

"write the file quick cmd.
nnoremap <Leader>s :write<Enter>
"quit quickly without writing.
nnoremap <Leader>q :q!<Enter>
"save and quit.
nnoremap <Leader>w :wq!<Enter>

"Remove highlight in search.
nnoremap <Leader>h :nohl<Enter>

" buffers navigation
nnoremap <Leader>bb :edit 
nnoremap <Leader>bl :ls<CR>
nnoremap <Leader>ba :badd 
nnoremap <Leader>bd :bdelete 
nnoremap <Leader>bw :bwipeout 
nnoremap <Leader>bwp :bwipeout<CR>
nnoremap <Leader>bp :bprevious<CR>
nnoremap <Leader>bn :bnext<CR>
nnoremap <Leader>tbp :sbprevious<CR>
nnoremap <Leader>tbn :sbnext<CR>
nnoremap <Leader>bft :bfirst<CR>
nnoremap <Leader>tbft :sbfirst<CR>
nnoremap <Leader>blt :blast<CR>
nnoremap <Leader>tblt :sblast<CR>

" tab navigation mappings
nnoremap <Leader>tp :tabp<CR>
nnoremap <Leader>tm :tabm 
nnoremap <Leader>tt :tabnew 
nnoremap <Leader>td :tab split<CR>
nnoremap <Leader>tn :tabn<CR>
nnoremap <Leader>tv :vs 
nnoremap <Leader>th :sp 


"map numbertoggle 
nnoremap <Leader>nu :NumbersToggle<Enter>
nnoremap <Leader>dt :r !python3 ~/.personal/.time.py date<Enter>o<esc><Leader>dtt
nnoremap <Leader>dtt :r !python3 ~/.personal/.time.py time<Enter><esc>0i## <esc>o
nnoremap <Leader>ip vip<C-v><S-i><tab><esc> 
nnoremap <Leader>uip vip< 

nnoremap <Leader>cp vip<C-v><S-i>#<esc> 
nnoremap <Leader>cl ^i# <esc>
nnoremap <Leader>cs <C-v><S-i># <esc>
nnoremap <Leader>dp <S-[>i'''<esc><S-]>i'''<esc>2<C-o>
nnoremap <Leader>ds <S-i>i'''<esc><C-o>i'''<esc><C-o>

nnoremap <Leader>ucs <C-v>x<esc>

"Write selected lines to python file

vnoremap <Leader>pw :w .temp.swp<CR>j
vnoremap <Leader>pa :w! >> .dump.swp<CR>
nnoremap <Leader>pra :read !python3 .dump.swp<CR><CR>
nnoremap <Leader>prw :read !python3 .temp.swp && rm .temp.swp <CR><CR>
nnoremap <Leader>prd :!rm .dump.swp .temp.swp <CR><CR>

nnoremap <Leader>pd <C-{>o```python<Esc><C-}>o```<CR><Esc>
nnoremap <Leader>dc <C-{>o```<Esc><C-}>o```<CR><Esc>
"map terminal esc
"tnoremap kj :<C-\><C-n>
"map <Leader>t :term<CR>
