nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>

" Leader keys
let mapleader = " "
let maplocalleader = ","

" Which key
nnoremap <silent><leader><space> :<c-u>WhichKey '<Space>'<CR>
nnoremap <silent> <localleader>, :WhichKey ','<CR>
call which_key#register('<Space>', "g:which_key_map")
call which_key#register(',', "g:which_key_map_local")
let g:which_key_map =  {}
let g:which_key_map_local = {}

" Root
nnoremap <leader><Tab> :NERDTreeToggle<cr>

" Remap keys for gotos
nmap <localleader>gg <Plug>(coc-definition)
nmap <localleader>gt <Plug>(coc-type-definition)
nmap <localleader>gn <Plug>(coc-rename)
nmap <localleader>gf <Plug>(coc-fix-current)
nmap <localleader>gi <Plug>(coc-implementation)
nmap <localleader>rr :CocRestart<cr>

" Remap for compiler
nmap <localleader>cb :T yarn build<cr>
nmap <localleader>cc :T yarn build-clean<cr>

" Remap for testing
nmap <localleader>tt :T yarn test<cr>
nmap <localleader>tf :<C-u>call RunTestFile()<cr>
function! RunTestFile()
  let file=expand("%:r")
  let extention=expand("%:e")
  let ending=get(split(file, "_"), 1)
  if !empty(ending) && ending == "test" && extention == "re"
    execute ":T yarn test " . file.".bs.js"
  elseif extention == "re"
    execute ":T yarn test " . file."_test.bs.js"
  endif
endfunction
nmap <localleader>tg :<C-u>call GoToTestFile()<cr>
function! GoToTestFile()
  let file=expand("%:r")
  execute ":edit " . file."_test.re"
endfunction

" Terminal Use Escape to exit
:tnoremap <Esc> <C-\><C-n>:q!<cr>

" Buffer management
nnoremap <leader>bd :BD<cr>
nnoremap <leader>bf :bfirst<cr>
nnoremap <leader>bl :blast<cr>
nnoremap <leader>bn :bn<cr>
nnoremap <leader>bp :bp<cr>
nnoremap <leader>bb :Buffers<CR>
nnoremap <leader>bx :bd<cr>

let g:which_key_map.b = {
  \ 'name' : 'Buffer' ,
  \ 'd' : 'first-buffer' ,
  \ 'l' : 'last-buffer' ,
  \ 'n' : 'next-buffer' ,
  \ 'p' : 'prev-buffer' ,
  \ 'b' : 'show-all' ,
  \ 'x' : 'delete-buffer' ,
  \}

" Window management
let i = 1
while i <= 9
    execute 'nnoremap <Leader>' . i . ' :' . i . 'wincmd w<CR>'
    let i = i + 1
endwhile

nnoremap <leader>wv :vsp<cr>
nnoremap <leader>wh :sp<cr>
nnoremap <leader>wd <C-w>c<cr>
nnoremap <leader>wo <C-w>o<cr>
nnoremap <leader>wn :new<cr>
nnoremap <leader>we <C-w>=<cr>

let g:which_key_map.w = {
  \ 'name' : 'Window' ,
  \ 'v' : 'vsplit' ,
  \ 'h' : 'hsplit' ,
  \ 'd' : 'delete-window' ,
  \ 'o' : 'delete-others' ,
  \ 'n' : 'new-empty' ,
  \ 'e' : 'equal-windows' ,
  \}

" File
nnoremap <leader>fs :w<cr>
nnoremap <leader>fed :vsplit $MYVIMRC<cr>
nnoremap <leader>fer :source $MYVIMRC<cr>
nnoremap <leader>feR :source $MYVIMRC \| :PlugInstall<cr>

let g:which_key_map.f = {
  \ 'name' : 'File' ,
  \ 'e' : {
    \ 'name' : 'Settings' ,
    \ 'd' : 'init-open' ,
    \ 'r' : 'reload-init' ,
    \} ,
  \}

" Quit
nnoremap <leader>qq :qa<cr>

let g:which_key_map.q = {
  \ 'name' : 'Quit' ,
  \ 'q' : 'quit-vim'
  \}

" Project
nnoremap <leader>pf :Files<cr>

let g:which_key_map.p = {
  \ 'name' : 'Project' ,
  \ 'f' : 'find-files'
  \}

" Comments
nmap <leader>cl <Plug>CommentaryLine
vmap <leader>cl <Plug>Commentary

let g:which_key_map.c = {
      \ 'name' : 'Comment' ,
      \ 'l' : 'comment-lines'
  \}

" Git
nnoremap <leader>gs :Git<cr>
nnoremap <leader>gl :Glog<cr>
nnoremap <leader>gb :Gblame<cr>
nnoremap <leader>gd :Gdiff<cr>

let g:which_key_map.g = {
      \ 'name' : 'Git' ,
      \ 's' : 'git-status' ,
      \ 'l' : 'git-log' ,
      \ 'b' : 'git-blame' ,
      \ 'd' : 'git-diff' ,
      \}

" Search
nnoremap <leader>sn :noh<cr>

" Tabs
nnoremap <leader>tt :tabnew<cr>
nnoremap <leader>tc :tabclose<cr>
nnoremap <leader>tn :tabnext<cr>
nnoremap <leader>tp :tabprevious<cr>

let g:which_key_map.t = {
      \ 'name' : 'Tabs' ,
      \ 't' : 'new-tab' ,
      \ 'n' : 'next-tab' ,
      \ 'p' : 'previous-tab' ,
      \ 'c' : 'close-tab' ,
      \}
