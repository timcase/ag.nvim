" Providers of view search results:
function! ag#view#auto(func)
  let l:fnm = 'ag#view#' . a:func
  if !exists('*'.l:fnm)
    throw "Err: 'autoload/ag/view.vim' has no '".fnm."' view provider."
  endif
  return l:fnm
endfunction


function! ag#view#qf(args, cmd)
  call ag#qf#search(a:args, a:cmd)
endfunction


function! ag#view#loc(args, cmd)
  call ag#qf#search(a:args, 'l'.a:cmd)
endfunction


function! ag#view#grp(args, cmd)
  call ag#group#search(a:args, a:cmd)
endfunction
