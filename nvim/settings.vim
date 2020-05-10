syntax enable
set background=dark

set autoindent
set autoread
set backspace=eol,start,indent
set conceallevel=0
set encoding=utf-8
set expandtab
set fileencoding=utf-8
set hidden
set history=10000
set hlsearch
set ignorecase
set lazyredraw
set lcs=trail:·,tab:»·
set mouse=a
set nolist
set notimeout
set number
set numberwidth=4
set scrolloff=5
set shiftwidth=2
set showmatch
set smartcase
set softtabstop=2
set splitbelow
set splitright
set tabstop=2
set termguicolors
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
set wildignore+=*/node_modules/*
set wildmenu
set wrap

set termguicolors
let ayucolor="mirage"
colorscheme ayu

autocmd VimResized * wincmd =

set nocompatible
filetype plugin on
set laststatus=2

if $TERM_PROGRAM =~ "iTerm"
  let &t_SI = "\<Esc>]50;CursorShape=1\x7" " Vertical bar in insert mode
  let &t_EI = "\<Esc>]50;CursorShape=0\x7" " Block in normal mode
endif 

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:neoterm_default_mod='belowright'
let g:neoterm_autoscroll=1
let g:neoterm_autoinsert=1

let g:indentLine_setConceal = 0
let g:indentLine_concealcursor = ""

let g:NERDTreeQuitOnOpen = 1
