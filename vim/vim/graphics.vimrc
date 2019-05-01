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



"1. terminal color settings
if has("gui_running")	" GUI color and font settings
	set guifont=Courier:h18
	set background=dark
	set t_Co=256		" 256 color mode
	set cursorline	" highlight current line
	highlight CursorLine  guibg=#003853 ctermbg=24  gui=none cterm=none
	colorsheme solarized
"else
"	colors evening
endif

