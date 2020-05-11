call plug#begin('~/.vim/plugged')
  "" Theme
  Plug 'ayu-theme/ayu-vim' " Ayu color theme

  "" Theme extensions
  Plug 'scrooloose/nerdtree' " NERDtree for file exploring
  Plug 'miyakogi/conoline.vim' " Highlight current line
  Plug 'qpkorr/vim-bufkill' " Sane buffer killing
  Plug 'vim-airline/vim-airline' " Airline statusbar
  Plug 'vim-airline/vim-airline-themes' " Themes for Airline statusbar
  Plug 'luochen1990/rainbow' " Rainbow brackets
  Plug 'tpope/vim-fugitive' " Git
  Plug 'airblade/vim-gitgutter' " Gitgutter
  Plug 'jiangmiao/auto-pairs' " Auto pairs for brackets etc
  Plug 'vim-scripts/ReplaceWithRegister' " Replace motion with register
  Plug 'tpope/vim-commentary' " Comment out lines
  Plug 'tpope/vim-abolish' " Easy text relacement
  Plug 'tpope/vim-surround' " Surround plugin
  Plug 'voldikss/vim-floaterm' " Floating terminal
  Plug 'liuchengxu/vim-which-key' " Which key menus for mnemonics
  
  "" FZF
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim' 
  
  "" Coc
  Plug 'neoclide/coc.nvim', {'branch': 'release'}

  "" Extensions
  Plug 'reasonml-editor/vim-reason-plus'
  Plug 'pangloss/vim-javascript'
  Plug 'leafgarland/typescript-vim'
  Plug 'maxmellon/vim-jsx-pretty'
  Plug 'jparise/vim-graphql'

call plug#end()

let g:rainbow_active = 1 "set to 0 if you want to enable it later via :RainbowToggle

let g:WorkspaceFolders = [
 \ '/home/bragur/ws-monorepo/src/mobile/projects/mobile-app',
 \ '/home/bragur/ws-monorepo/src/solum/bidclient',
 \ '/home/bragur/ws-monorepo/src/solum/dls',
 \ ]
