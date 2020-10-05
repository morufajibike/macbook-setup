set autoindent
set cindent
set mouse=a
set number
syntax on
set tabstop=2
set autoindent
set expandtab
set softtabstop=2
colorscheme industry
set laststatus=2

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Keep Plugin commands between vundle#begin/end.
" " plugin on GitHub repo

Plugin 'preservim/nerdtree'
Plugin 'nvie/vim-flake8'
Plugin 'vim-airline/vim-airline'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

nmap <C-t> :NERDTreeToggle<CR>

execute pathogen#infect()

autocmd BufWritePost *.py call flake8#Flake8()

augroup myvimrc
    au!
    au BufWritePost .vimrc,_vimrc,vimrc,.gvimrc,_gvimrc,gvimrc so $MYVIMRC | if has('gui_running') | so $MYGVIMRC | endif
augroup END

syntax on
autocmd VimEnter * NERDTree

