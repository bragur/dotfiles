syntax enable
set background=dark

set autoindent
set autoread
set backspace=eol,start,indent
set conceallevel=0
set encoding=utf-8
set expandtab
set hidden
set history=10000
set hlsearch
set ignorecase
set lcs=trail:·,tab:»·
set mouse=a
set nolist
set notimeout
set number
set numberwidth=4
set pyxversion=3
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
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
colorscheme Gruvbox
" let g:oceanic_next_terminal_bold = 1
" let g:oceanic_next_terminal_italic = 1
" colorscheme OceanicNext
  

set completeopt=menuone,noinsert
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']

"" Equalize windows on resize
autocmd VimResized * wincmd =

set nocompatible
filetype plugin on
set laststatus=2

" if $TERM_PROGRAM =~ "iTerm"
"   let &t_SI = "\<Esc>]50;CursorShape=1\x7" " Vertical bar in insert mode
"   let &t_EI = "\<Esc>]50;CursorShape=0\x7" " Block in normal mode
" endif 

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

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:neoterm_default_mod='belowright'
let g:neoterm_autoscroll=1
let g:neoterm_autoinsert=1

"" Configure NERDTree
let g:NERDTreeQuitOnOpen = 1
let NERDTreeShowHidden=1

"" Configure Airline
let g:airline#extensions#tabline#enabled = 1
" let g:airline_theme='gruvbox'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#formatter = 'default'
let g:airline_powerline_fonts = 0
let g:airline_left_sep = ''
let g:airline_right_sep = ''

function! <SID>FormatSync()
    let l = line(".")
    let c = col(".")
    lua vim.lsp.buf.formatting_sync(nil, 1000)
    call cursor(l, c)
endfun

autocmd BufWritePost *.re :call <SID>FormatSync()
autocmd BufWritePost *.rei :call <SID>FormatSync()
autocmd BufWritePost *.ts  :call <SID>FormatSync()

let g:AutoPairs = {'(':')', '[':']', '{':'}', "'":"'", '"':'"', '```':'```', '"""':'"""', "'''":"'''", "<":">"}
" ## added by OPAM user-setup for vim / base ## 93ee63e278bdfc07d1139a748ed3fff2 ## you can edit, but keep this line
let s:opam_share_dir = system("opam config var share")
let s:opam_share_dir = substitute(s:opam_share_dir, '[\r\n]*$', '', '')

let s:opam_configuration = {}

function! OpamConfOcpIndent()
  execute "set rtp^=" . s:opam_share_dir . "/ocp-indent/vim"
endfunction
let s:opam_configuration['ocp-indent'] = function('OpamConfOcpIndent')

function! OpamConfOcpIndex()
  execute "set rtp+=" . s:opam_share_dir . "/ocp-index/vim"
endfunction
let s:opam_configuration['ocp-index'] = function('OpamConfOcpIndex')

function! OpamConfMerlin()
  let l:dir = s:opam_share_dir . "/merlin/vim"
  execute "set rtp+=" . l:dir
endfunction
let s:opam_configuration['merlin'] = function('OpamConfMerlin')

let s:opam_packages = ["ocp-indent", "ocp-index", "merlin"]
let s:opam_check_cmdline = ["opam list --installed --short --safe --color=never"] + s:opam_packages
let s:opam_available_tools = split(system(join(s:opam_check_cmdline)))
for tool in s:opam_packages
  " Respect package order (merlin should be after ocp-index)
  if count(s:opam_available_tools, tool) > 0
    call s:opam_configuration[tool]()
  endif
endfor
" ## end of OPAM user-setup addition for vim / base ## keep this line

