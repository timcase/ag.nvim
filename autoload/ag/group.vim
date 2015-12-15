function! ag#group#search(args, frgx)
  let l:grepargs = a:args
  let fileregexp = (a:frgx==#'' ?'': '-G '.a:frgx)
  let context = (v:count<1 ?'': '-C '.v:count)

  silent! wincmd P
  if !&previewwindow
    exe g:ag.nhandler
    execute  'resize ' . &previewheight
    set previewwindow
  endif

  setlocal modifiable

  execute "silent %delete_"

  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nowrap

  "--vimgrep doesn't work well here
  execute 'silent read !' . g:ag.bin . ' -S --group --column ' . context . ' ' . fileregexp . ' ' . l:grepargs

  setfiletype ag
  " RFC: move into 'ftplugin/ag.vim', but too tightly linked with l:grepargs

  if !empty(fileregexp) && match(l:grepargs, '\C[A-Z]') == -1
    "explicit file-filter and search in lower case
    syn case ignore
  endif

  syn match agLine /^\d\+:\d\+:/ conceal
  syn match agLineContext /^\d\+-/ conceal
  syn match agFile /^\n.\+$/hs=s+1
  if hlexists('agSearch')
    silent syn clear agSearch
  endif
  if l:grepargs =~# '^"'
    "detect "find me" file1 file2
    let l:grepargs = split(l:grepargs, '"')[0]
  elseif l:grepargs =~# "^'"
    let l:grepargs = split(l:grepargs, "'")[0]
  else
    let l:grepargs = split(l:grepargs, '\s\+')[0]
  endif
  let l:grepargs = substitute(l:grepargs, '/', '\\/', 'g')

  try
    try
      execute 'syn match agSearch /' . escape(l:grepargs, "\|()") . '/'
    catch /^Vim\%((\a\+)\)\=:E54/ " invalid regexp
        execute 'syn match agSearch /' . l:grepargs . '/'
    endtry
  catch
  endtry
endfunction
