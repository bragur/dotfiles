""""""""""""""""""""""""""""""""""""""""""""""
" WHICH KEY SETUP
""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <silent><leader><space> :<c-u>WhichKey '<Space>'<CR>
nnoremap <silent> <localleader>, :WhichKey ','<CR>
call which_key#register('<Space>', "g:which_key_map")
call which_key#register(',', "g:which_key_map_local")
let g:which_key_map =  {}
let g:which_key_map_local = {}

""""""""""""""""""""""""""""""""""""""""""""""
" BUFFER
""""""""""""""""""""""""""""""""""""""""""""""
let g:which_key_map.b = { 'name' : '+Buffer' }
let g:which_key_map.b.a = 'last-used-buffer'
let g:which_key_map.b.b = 'show-all'
let g:which_key_map.b.d = 'delete-buffer'
let g:which_key_map.b.e = 'empty-buffer'
let g:which_key_map.b.l = 'last-buffer'
let g:which_key_map.b.n = 'next-buffer'
let g:which_key_map.b.o = 'del-other-buffers'
let g:which_key_map.b.p = 'prev-buffer'

""""""""""""""""""""""""""""""""""""""""""""""
" WINDOW
""""""""""""""""""""""""""""""""""""""""""""""
let g:which_key_map.w = { 'name' : '+window' }
let g:which_key_map.w.0 = 'equal-windows'
let g:which_key_map.w.1 = 'one-window-layout'
let g:which_key_map.w.2 = 'two-window-layout'
let g:which_key_map.w.3 = 'three-window-layout'
let g:which_key_map.w.4 = 'four-window-layout'
let g:which_key_map.w.d = 'delete-window'
let g:which_key_map.w.e = '+ resize-horizontal'
let g:which_key_map.w.h = '- resize-vertical'
let g:which_key_map.w.i = '+ resize-vertical'
let g:which_key_map.w.n = '- resize-horizontal'
let g:which_key_map.w.o = 'delete-others'
let g:which_key_map.w.s = { 'name' : '+Split' }
let g:which_key_map.w.s.h = 'h-split'
let g:which_key_map.w.s.v = 'v-split'
let g:which_key_map.w.t = { 'name' : '+Tabs' }
let g:which_key_map.w.t.c = 'close-tab'
let g:which_key_map.w.t.n = 'next-tab'
let g:which_key_map.w.t.p = 'previous-tab'
let g:which_key_map.w.t.t = 'new-tab'

""""""""""""""""""""""""""""""""""""""""""""""
" FILE
""""""""""""""""""""""""""""""""""""""""""""""
let g:which_key_map.f = { 'name' : '+File' }
let g:which_key_map.f.e = { 'name' : '+Settings' }
let g:which_key_map.f.e.R = 'reload-init'
let g:which_key_map.f.e.d = 'init-open'
let g:which_key_map.f.n = 'open-file-dir'
let g:which_key_map.f.s = 'save-file'

""""""""""""""""""""""""""""""""""""""""""""""
" QUIT
""""""""""""""""""""""""""""""""""""""""""""""
let g:which_key_map.q = { 'name' : '+Quit' }
let g:which_key_map.q.q = 'quit-vi'

""""""""""""""""""""""""""""""""""""""""""""""
" PROJECT
""""""""""""""""""""""""""""""""""""""""""""""
let g:which_key_map.p = { 'name' : '+project' }
let g:which_key_map.p.f = 'find-file'

""""""""""""""""""""""""""""""""""""""""""""""
" COMMENT
""""""""""""""""""""""""""""""""""""""""""""""
let g:which_key_map.c = { 'name' : '+Comment' }
let g:which_key_map.c.l = 'comment-line'

""""""""""""""""""""""""""""""""""""""""""""""
" GIT
""""""""""""""""""""""""""""""""""""""""""""""
let g:which_key_map.g = { 'name' : '+Git' }
let g:which_key_map.g.b = 'git-blame'
let g:which_key_map.g.d = 'git-diff'
let g:which_key_map.g.l = 'git-log'
let g:which_key_map.g.s = 'git-status'

""""""""""""""""""""""""""""""""""""""""""""""
" SEARCH
""""""""""""""""""""""""""""""""""""""""""""""
let g:which_key_map.s = { 'name' : '+Search' }
let g:which_key_map.s.n = 'reset-search'

""""""""""""""""""""""""""""""""""""""""""""""
" TERMINAL
""""""""""""""""""""""""""""""""""""""""""""""
let g:which_key_map.t = { 'name' : '+Terminal' }
let g:which_key_map.t.t = 'new-float-term'
let g:which_key_map.t.q = 'kill-float-term'
