 call plug#begin('~/.vim/plugged')
  Plug 'liuchengxu/vim-which-key'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-abolish'
  Plug 'vim-scripts/ReplaceWithRegister'
  Plug '/usr/local/opt/fzf'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim' 
  Plug 'reasonml-editor/vim-reason-plus'
  Plug 'luochen1990/rainbow'
  Plug 'vim-airline/vim-airline'
  Plug 'kassio/neoterm'
  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'
  Plug 'tpope/vim-commentary'
  Plug 'miyakogi/conoline.vim'
  Plug 'qpkorr/vim-bufkill'
  Plug 'scrooloose/nerdtree'
  Plug 'pangloss/vim-javascript'
  Plug 'leafgarland/typescript-vim'
  Plug 'maxmellon/vim-jsx-pretty'
  Plug 'jparise/vim-graphql'
  Plug 'ayu-theme/ayu-vim'
  Plug 'haishanh/night-owl.vim'

	" for neovim
	if has('nvim')
		Plug 'neoclide/coc.nvim', {'branch': 'release'}
	" for vim 8 with python
	else
	  Plug 'Shougo/deoplete.nvim'
	  Plug 'roxma/nvim-yarp'
	  Plug 'roxma/vim-hug-neovim-rpc'
	  " the path to python3 is obtained through executing `:echo exepath('python3')` in vim
	  let g:python3_host_prog = "/usr/local/bin/python3"
	endif

  Plug  'Yggdroot/indentLine'
call plug#end()

" COC.vim begin
let g:coc_global_extensions = [
  \ 'coc-snippets',
  \ 'coc-pairs',
  \ 'coc-eslint', 
  \ 'coc-prettier', 
  \ 'coc-json', 
  \ 'coc-tsserver',
  \ 'coc-reason', 
  \ ]

let g:rainbow_active = 1 "set to 0 if you want to enable it later via :RainbowToggle

let g:WorkspaceFolders = [
 \ '/home/bragur/ws-monorepo/src/mobile/projects/mobile-app',
 \ '/home/bragur/ws-monorepo/src/solum/bidclient',
 \ '/home/bragur/ws-monorepo/src/solum/dls',
 \ ]
