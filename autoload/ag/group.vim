" TODO: replace by direct patt supplying from bind args list
function! ag#group#get_patt(p)
  return
    \ a:p =~# '^"' ? split(a:p, '"')[0] :
    \ a:p =~# "^'" ? split(a:p, "'")[0] :
    \ split(a:p, '\s\+')[0]
endfunction


function! ag#group#search(args, frgx)
  silent! wincmd P
  if !&previewwindow
    exe g:ag.nhandler
    execute  'resize ' . &previewheight
    set previewwindow
  endif
  setlocal modifiable
  execute "silent %delete_"
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nowrap

  let fileregexp = (a:frgx==#'' ?'': '-G '.a:frgx)
  let context = (v:count<1 ?'': '-C '.v:count)
  let l:cmdline = g:ag.bin.' -S --group --column '.fileregexp.' '.context.' '.a:args
  silent! put = systemlist(l:cmdline)
  1delete _
  setlocal nomodifiable

  " NOTE: no need to escape, as after shellescape() it has embedded single
  " quotes. Simply use "exe 'syn match agSearch'.b:patt"?
  let b:pattern = escape(ag#group#get_patt(a:args), '/')
  "explicit file-filter and search in lower case
  let b:ignore_case = !empty(fileregexp) && (b:pattern !~# '[A-Z]')

  setfiletype ag
endfunction
