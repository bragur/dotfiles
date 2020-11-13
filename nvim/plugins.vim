call plug#begin('~/.vim/plugged')
  "" Theme extensions
  Plug 'morhetz/gruvbox'
  Plug 'scrooloose/nerdtree' " NERDtree for file exploring
  Plug 'qpkorr/vim-bufkill' " Sane buffer killing
  Plug 'vim-airline/vim-airline' " Airline statusbar
  Plug 'vim-airline/vim-airline-themes' " Themes for Airline statusbar
  Plug 'airblade/vim-gitgutter' " Gitgutter
  Plug 'vim-scripts/ReplaceWithRegister' " Replace motion with register
  Plug 'tpope/vim-commentary' " Comment out lines
  Plug 'tpope/vim-abolish' " Easy text replacement
  Plug 'tpope/vim-surround' " Surround plugin
  Plug 'tpope/vim-eunuch' " Sugar for shell commands
  Plug 'tpope/vim-unimpaired' " Mnemonics
  Plug 'voldikss/vim-floaterm' " Floating terminal
  Plug 'liuchengxu/vim-which-key' " Which key menus for mnemonics
  Plug 'kassio/neoterm' " Same terminal
  Plug 'jiangmiao/auto-pairs' " Auto pairs
  Plug 'sheerun/vim-polyglot' " Multi language syntax highlighting
  Plug 'ryanoasis/vim-devicons' " Icons
  Plug 'pangloss/vim-javascript'
  Plug 'mhinz/vim-startify'

  "" FZF
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim' 
  

  "" Language server
  Plug 'neovim/nvim-lspconfig'
  Plug 'nvim-lua/completion-nvim'
call plug#end()

lua <<EOF
require'nvim_lsp'.ocamllsp.setup{ on_attach=require'completion'.on_attach }
require'nvim_lsp'.tsserver.setup{ on_attach=require'completion'.on_attach }
EOF
