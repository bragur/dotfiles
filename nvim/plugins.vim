call plug#begin('~/.vim/plugged')
  Plug 'liuchengxu/vim-which-key'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-abolish'
  Plug 'vim-scripts/ReplaceWithRegister'
  Plug '/usr/local/opt/fzf'
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim' 
  Plug 'luochen1990/rainbow'
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
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
  Plug 'Yggdroot/indentLine'
  Plug 'voldikss/vim-floaterm'
  Plug 'jiangmiao/auto-pairs'
  Plug 'ayu-theme/ayu-vim'

  Plug 'reasonml-editor/vim-reason-plus'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

let g:rainbow_active = 1 "set to 0 if you want to enable it later via :RainbowToggle

let g:WorkspaceFolders = [
 \ '/home/bragur/ws-monorepo/src/mobile/projects/mobile-app',
 \ '/home/bragur/ws-monorepo/src/solum/bidclient',
 \ '/home/bragur/ws-monorepo/src/solum/dls',
 \ ]
