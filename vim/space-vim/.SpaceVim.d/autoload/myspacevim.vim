function! myspacevim#before() abort

  ""'''''''''''/////////////////// Flutter coc-flutter //////////////
  nnoremap <Leader>fpg :CocCommand flutter.pub.get<CR>
  nnoremap <Leader>fr :CocCommand flutter.run<CR>
  nnoremap <Leader>fg :CocCommand flutter.gotoSuper<CR>
  
  ""'''''''''''/////////////////// Flutter dart-vim-plugin//////////////
  let g:dart_style_guide = 2
  let g:dart_format_on_save = 1
  
  "'''''''''''/////////////////// Python coc-python //////////////
  nnoremap <Leader>pi :CocCommand python.setInterpreter<CR>
  nnoremap <Leader>pe :CocCommand python.execInTerminal<CR>
  nnoremap <Leader>pr :CocCommand python.startREPL<CR>  "let g:neomake_enabled_c_makers = ['clang']

endfunction

function! myspacevim#after() abort

endfunction
