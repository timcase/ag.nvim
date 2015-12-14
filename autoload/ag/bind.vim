function! ag#bind#escape(arg)
  let e = escape(a:arg, '%#')
  if e =~# '^".*"$' || e =~# "^'.*'$"
    return escape(e, '%#')  " Double %# escaping
  else
    return shellescape(e)
  endif
endfunction


function! ag#bind#join(args)
  return join(map(a:args, 'ag#bind#escape(v:val)'))
endfunction


function! ag#bind#call(entry)
  " FIND: another way -- to execute args list directly without join?
  let l:args = ag#bind#join(a:entry.args + a:entry.paths)
  call {a:entry.view}(a:entry.cmd, l:args)
endfunction


function! ag#bind#fix_fargs(args)
  if len(a:args) < 2 | return a:args | endif
  let a = a:args
  for i in range(0, len(a) - 2)
    if (a[i] =~# '^".*[^"]$' && a[i+1] =~# '^[^"].*"$')
    \||(a[i] =~# "^'.*[^']$" && a[i+1] =~# "^[^'].*'$")
      let a[i] .= ' '.remove(a, i+1)
    endif
  endfor
  return a
endfunction


" THINK: separate flags and regex?
function! ag#bind#f(view, args, paths, cmd)
  if !empty(a:args) && type(a:args)==type([])
    let l:args = ag#bind#fix_fargs(a:args)
  else
    let l:args = ag#args#auto(a:args)
  endif
  if empty(l:args) | echom "empty search" | return | endif

  let g:ag.last = {'view': ag#view#auto(a:view), 'args': l:args,
        \ 'paths': ag#paths#auto(a:paths), 'cmd': a:cmd}

  call ag#bind#call(g:ag.last)
endfunction
