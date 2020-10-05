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

nmap <C-t> :NERDTreeToggle<CR>

execute pathogen#infect()

autocmd BufWritePost *.py call flake8#Flake8()

augroup myvimrc
    au!
    au BufWritePost .vimrc,_vimrc,vimrc,.gvimrc,_gvimrc,gvimrc so $MYVIMRC | if has('gui_running') | so $MYGVIMRC | endif
augroup END

syntax on
filetype plugin indent on
autocmd VimEnter * NERDTree

