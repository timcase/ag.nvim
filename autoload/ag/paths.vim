function! ag#paths#buffers(cmd, args)
  let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val)')
  let l:files = []
  for buf in l:bufs
    let l:file = fnamemodify(bufname(buf), ':p')
    if !isdirectory(l:file)
      call add(l:files, l:file)
    endif
  endfor
  call ag#Ag(a:cmd, a:args . ' ' . join(l:files, ' '))
endfunction

function! s:GetDocLocations()
  let dp = ''
  for p in split(&runtimepath,',')
    let p = p.'doc/'
    if isdirectory(p)
      let dp = p.'*.txt '.dp
    endif
  endfor
  return dp
endfunction

function! ag#paths#help(cmd,args)
  let args = a:args.' '.s:GetDocLocations()
  call ag#Ag(a:cmd,args)
endfunction
