set autoindent
set cindent
set mouse=a
set number
syntax on
set softtabstop=4
set tabstop=2
set expandtab
set shiftwidth=2
colorscheme slate
set laststatus=2

" Enable folding
set foldmethod=indent
set foldlevel=99

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialise
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Plugins
Plugin 'preservim/nerdtree'
Plugin 'nvie/vim-flake8'
Plugin 'vim-airline/vim-airline'
Plugin 'tmhedberg/SimpylFold'
Plugin 'github/copilot.vim'

" Markdown
Plugin 'godlygeek/tabular'
Plugin 'preservim/vim-markdown'
Plugin 'iamcco/markdown-preview.nvim'

" All Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

nmap <C-t> :NERDTreeToggle<CR>

" Enable folding with the spacebar
nnoremap <space> za

autocmd BufWritePost *.py call flake8#Flake8()
autocmd FileType markdown setlocal conceallevel=2
autocmd FileType markdown command! -buffer Glow execute '!glow -p ' . shellescape(expand('%'), 1)
let g:mkdp_open_to_the_world = 0

augroup myvimrc
    au!
    au BufWritePost .vimrc,_vimrc,vimrc,.gvimrc,_gvimrc,gvimrc so $MYVIMRC | if has('gui_running') | so $MYGVIMRC | endif
augroup END

syntax on
autocmd VimEnter * NERDTree
