let g:coc_global_extensions = [
  \ 'coc-snippets' ,
  \ 'coc-eslint' , 
  \ 'coc-reason' , 
  \ 'coc-tsserver' ,
  \ 'coc-pairs' ,
  \ ]

nmap <localleader>rr :CocRestart<cr>
nmap <localleader>gg <Plug>(coc-definition)
vmap <localleader>gg <Plug>(coc-definition)
nmap <localleader>ht :call CocActionAsync('doHover')<CR>
vmap <localleader>ht :call CocActionAsync('doHover')<CR>
nmap <localleader>gi <Plug>(coc-implementation)
nmap <localleader>gr <Plug>(coc-references)
nmap <localleader>== <Plug>(coc-format)
vmap <localleader>== <Plug>(coc-format-selected)
nmap <silent> <leader>en <Plug>(coc-diagnostic-next)
nmap <silent> <leader>eN <Plug>(coc-diagnostic-prev)
