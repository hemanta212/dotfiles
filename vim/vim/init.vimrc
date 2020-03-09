"reload after editing it
autocmd! bufwritepost init.vimrc source ~/.vimrc

set nocompatible              " required
filetype off                  " required

" ============================================================================
" Vim-plug initialization
" Avoid modify this section, unless you are very sure of what you are doing

let vim_plug_just_installed = 0
let vim_plug_path = expand('~/.vim/autoload/plug.vim')
if !filereadable(vim_plug_path)
    echo "Installing Vim-plug..."
    echo ""
    silent !mkdir -p ~/.vim/autoload
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
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
call plug#begin('~/.vim/bundle')

" Now the actual plugins:

" Override configs by directory


"PLUGINS LIST:
"plugin related to folding (from realpython.1st addition.)
    Plug 'tmhedberg/SimpylFold'
"plugin for autoidentation in python.
    Plug 'vim-scripts/indentpython.vim'
"
"Plugin for syntax highlightion.
    Plug 'vim-syntastic/syntastic'
"Inside File browsing using NerdTree plugin.
    Plug 'scrooloose/nerdtree'
"Utilize tabs in NerdTree
    Plug 'jistr/vim-nerdtree-tabs'
"TO search basically anything from vim.(Use it by ctrl + p.
    Plug 'kien/ctrlp.vim'
"Enable Basic git cmds inside the vim.
    Plug 'tpope/vim-fugitive'
"PEP-8 checking syntax plugin.
    Plug 'nvie/vim-flake8'
"Autocomplettion plugin by Neo.
    Plug 'shougo/neocomplete.vim'
"Autocomplete by Valloric. Use one bet neo and valloric's.
"	  Plug 'Valloric/YouCompleteMe'
"plugin for theme Zenburn for CLI and another for GUI.(its logic is below).
    Plug 'jnurmine/Zenburn'
    Plug 'altercation/vim-colors-solarized'
"emmet plugin for html css and js etc
    Plug 'mattn/emmet-vim'
"Enable the powerline (basic file info at buttom. (  :) My dream!!)
"   Plug 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
"plugin for cheat.sh
    Plug 'dbeniamine/cheat.sh-vim'

" Terminal Vim with 256 colors colorscheme
Plug 'fisadev/fisa-vim-colorscheme'

"tmux
Plug 'tpope/vim-obsession'
Plug 'christoomey/vim-tmux-navigator'

" Linters
Plug 'neomake/neomake'

" Plug 'fisadev/vim-ctrlp-cmdpalette'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'Shougo/context_filetype.vim'
" Python autocompletion
"Plug 'zchee/deoplete-jedi', { 'do': ':UpdateRemotePlugins' }
" Just to add the python go-to-definition and similar features, autocompletion
" from this plugin is disabled
"Plug 'davidhalter/jedi-vim'

"DEOPLETE VIM 
"if has('nvim')
"  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"else
"  Plug 'Shougo/deoplete.nvim'
"  Plug 'roxma/nvim-yarp'
"  Plug 'roxma/vim-hug-neovim-rpc'
"endif
 
"Flutter
Plug 'dart-lang/dart-vim-plugin'





" All of your Plugins must be added before the following line
call plug#end()
if vim_plug_just_installed
    echo "Installing Bundles, please ignore key map error messages"
    :PlugInstall
endif


