""""""""""""""""""""""""""""""""""""""""""""""
" LEADER KEYS SETUP
""""""""""""""""""""""""""""""""""""""""""""""
let mapleader = " "
let maplocalleader = ","

""""""""""""""""""""""""""""""""""""""""""""""
" ROOT
""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <leader><Tab> :NERDTreeToggle<cr>

""""""""""""""""""""""""""""""""""""""""""""""
" COMPILER REMAPS
""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <localleader>cb :FloatermNew --height=0.3 --width=0.3 --wintype=floating --name=build --position=topright --autoclose=1 yarn build<cr>
nnoremap <localleader>cc :FloatermNew --height=0.3 --width=0.3 --wintype=floating --name=build-clean --position=topright --autoclose=1 yarn build-clean<cr>
nnoremap <localleader>tf :<C-u>call RunTestFile()<cr>
nnoremap <localleader>tg :<C-u>call GoToTestFile()<cr>
nnoremap <localleader>tt :T yarn test<cr>

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

function! GoToTestFile()
  let file=expand("%:r")
  execute ":edit " . file."_test.re"
endfunction

""""""""""""""""""""""""""""""""""""""""""""""
" BUFFER
""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <leader>bb :Buffers<cr>
nnoremap <leader>bd :bd<cr>
nnoremap <leader>be :new<cr>
nnoremap <leader>bf :bfirst<cr>
nnoremap <leader>bl :blast<cr>
nnoremap <leader>bn :bn<cr>
nnoremap <leader>bo :NERDTreeClose<bar>:%bd<bar>e#<bar>bd#<cr>
nnoremap <leader>bp :bp<cr>

""""""""""""""""""""""""""""""""""""""""""""""
" WINDOW
""""""""""""""""""""""""""""""""""""""""""""""
let i = 1
while i <= 9
    execute 'nnoremap <leader>' . i . ' :' . i . 'wincmd w<CR>'
    let i = i + 1
endwhile
nnoremap <silent> <C-S-Left> :vertical resize -1<cr>
nnoremap <silent> <C-S-Right> :vertical resize +1<cr>
nnoremap <silent> <C-S-Down> :resize -1<cr>
nnoremap <silent> <C-S-Up> :resize +1<cr>

nnoremap <leader>w0 <C-w>=<cr>
nnoremap <leader>w1 <C-w>o<cr>
nnoremap <leader>w2 <C-w>o<bar>:vsp<bar>:1wincmd w<cr>
nnoremap <leader>w3 <C-w>o<bar>:vsp<bar>:vsp<bar>:1wincmd w<cr>
nnoremap <leader>w4 <C-w>o<bar>:vsp<bar>:sp<bar>:1wincmd w<bar>:sp<bar>:1wincmd w<cr>
nnoremap <leader>wd <C-w>c<cr>
nnoremap <leader>we :resize +1<cr>
nnoremap <leader>wh :vertical resize -1<cr>
nnoremap <leader>wi :vertical resize +1<cr>
nnoremap <leader>wn :resize -1<cr>
nnoremap <leader>wo <C-w>o<cr>
nnoremap <leader>wsh :sp<cr>
nnoremap <leader>wsv :vsp<cr>
nnoremap <leader>wtc :tabclose<cr>
nnoremap <leader>wtn :tabnext<cr>
nnoremap <leader>wtp :tabprevious<cr>
nnoremap <leader>wtt :tabnew<cr>

""""""""""""""""""""""""""""""""""""""""""""""
" FILE
""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <leader>feR :source $MYVIMRC<bar> :PlugInstall<cr>
nnoremap <leader>fed :vsplit $MYVIMRC<cr>
nnoremap <leader>fer :source $MYVIMRC<cr>
nnoremap <leader>fn :NERDTreeFind<cr>
nnoremap <leader>fs :w<cr>

""""""""""""""""""""""""""""""""""""""""""""""
" QUIT
""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <leader>qq :qa<cr>

""""""""""""""""""""""""""""""""""""""""""""""
" PROJECT
""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <leader>pt :FloatermNew fzf<cr>
nnoremap <leader>pf :FZF<cr>
nnoremap <leader>psd :Startify<cr>
nnoremap <leader>pss :SSave<cr>
nnoremap <leader>psx :SDelete<cr>

""""""""""""""""""""""""""""""""""""""""""""""
" COMMENT
""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <leader>cl <Plug>CommentaryLine
vmap <leader>cl <Plug>Commentary

""""""""""""""""""""""""""""""""""""""""""""""
" GIT
""""""""""""""""""""""""""""""""""""""""""""""
" Handles closing in cases where you would be the last window
function! CloseWindowOnSuccess(code) abort
  if a:code == 0
    let current_window = winnr()
    bdelete!
    " Handles special case where window remains due startify
    if winnr() == current_window
      close
    endif
  endif
endfunction

function! Lazygit()
  " Size variables
  let height = float2nr(&lines * 0.6) " 40% of screen
  let width = float2nr(&columns * 0.6) " 70% of screen
  let vertical = float2nr(&lines * 0.1) " space to top: 10%
  let horizontal = float2nr((&columns - width) / 2)

  let opts = {
        \ 'relative': 'editor',
        \ 'row': vertical,
        \ 'col': horizontal,
        \ 'width': width,
        \ 'height': height,
        \ 'anchor': 'NW',
        \ 'style': 'minimal'
        \ }

    let border_opts = {
        \ 'relative': 'editor',
        \ 'row': vertical - 1,
        \ 'col': horizontal - 2,
        \ 'width': width + 4,
        \ 'height': height + 2,
        \ 'style': 'minimal'
        \ }

  " Border variables
  let top = "╭" . repeat("─", width + 2) . "╮"
  let mid = "│" . repeat(" ", width + 2) . "│"
  let bot = "╰" . repeat("─", width + 2) . "╯"
  let lines = [top] + repeat([mid], height) + [bot]

  " Buffers
  let buf = nvim_create_buf(v:false, v:true)
  let border_buffer = nvim_create_buf(v:false, v:true)

  call nvim_buf_set_lines(border_buffer, 0, -1, v:true, lines)

  call nvim_open_win(border_buffer, v:true, border_opts)
  call nvim_open_win(buf, v:true, opts)
  call termopen('lazygit', {'on_exit': {_,c -> CloseWindowOnSuccess(c)}})
  startinsert
endfunction
nnoremap <leader>gb :Gblame<cr>
nnoremap <leader>gd :Gdiff<cr>
nnoremap <leader>gl :Glog<cr>
nnoremap <leader>gs :call Lazygit()<cr>

""""""""""""""""""""""""""""""""""""""""""""""
" SEARCH
""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <leader>sn :noh<cr>

""""""""""""""""""""""""""""""""""""""""""""""
" TERMINAL
""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <leader>tt :FloatermNew --wintype=floating<cr>
nnoremap <leader>tq :FloatermKill<cr>
tnoremap <localleader>tq <C-\><C-n><bar>:FloatermKill<cr>
nnoremap <leader>ts :FloatermShow<cr>
tnoremap <localleader>th <C-\><C-n><bar>:FloatermHide<cr>

