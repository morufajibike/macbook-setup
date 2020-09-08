set autoindent
set cindent
set mouse=a
set number

nmap <C-t> :NERDTreeToggle<CR>

execute pathogen#infect()

autocmd BufWritePost *.py call flake8#Flake8()

syntax on
filetype plugin indent on
autocmd VimEnter * NERDTree
