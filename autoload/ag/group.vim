function! s:VisualSelection()
  let selection = ""
  try
    let a_save = @a
    normal! gv"ay
    let selection = @a
  finally
    let @a = a_save
  endtry
  return selection
endfunction

let g:last_aggroup=""

function! ag#group#repeat(ncontext)
  call ag#group#search(a:ncontext, 0, '', g:last_aggroup)
endfunction

function! s:GetArgs(ncontext, visualmode, args)
  if !empty(a:args)
    let l:grepargs = a:args
  else
    if a:visualmode
      let l:grepargs = s:VisualSelection()
    else
      let l:grepargs = ""
    endif
    if empty(l:grepargs)
      let l:grepargs = expand("<cword>")
      if empty(l:grepargs)
        let l:grepargs = g:last_aggroup
      endif
    else
      let l:grepargs = '"' . l:grepargs . '"'
    endif
  endif
  return l:grepargs
endfunction

function! ag#group#tracked_search(ncontext, visualmode)
  call ag#group#search(a:ncontext, a:visualmode, '', '')
  if g:ag.mappings_to_cmd_history
     call histadd(":", "Agg" . " " . g:last_aggroup)
  endif
endfunction

function! ag#group#search(ncontext, visualmode, fileregexp, args)
  let l:grepargs = s:GetArgs(a:ncontext, a:visualmode, a:args)

  if empty(l:grepargs)
     echo "empty search"
     return
  endif

  let g:last_aggroup = l:grepargs

  silent! wincmd P
  if !&previewwindow
    exe g:ag.nhandler
    execute  'resize ' . &previewheight
    set previewwindow
  endif

  setlocal modifiable

  execute "silent %delete_"

  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nowrap

  let context = ''
  if a:ncontext > 0
    let context = '-C' . a:ncontext
  endif

  if empty(a:fileregexp)
    let fileregexp = ''
  else
    let fileregexp = '-G' . a:fileregexp
  endif

  let l:grepargs = substitute(l:grepargs, '#', '\\#','g')
  let l:grepargs = substitute(l:grepargs, '%', '\\%','g')
  "--vimgrep doesn't work well here
  let ag_prg = 'ag'
  execute 'silent read !' . ag_prg . ' -S --group --column ' . context . ' ' . fileregexp . ' ' . l:grepargs

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
  if l:grepargs =~ '^"'
    "detect "find me" file1 file2
    let l:grepargs = split(l:grepargs, '"')[0]
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
