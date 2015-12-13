function! ag#AgBuffer(cmd, args)
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

function! ag#Ag(cmd, args)
  " If no pattern is provided, search for the word under the cursor
  if empty(a:args)
    let l:grepargs = expand("<cword>")
  else
    let l:grepargs = a:args
  end

  if empty(l:grepargs)
    echo "Usage: ':Ag {pattern}' (or just :Ag to search for the word under the cursor). See ':help :Ag' for more information."
    return
  endif

  " Format, used to manage column jump
  if a:cmd =~# '-g$'
    let s:ag_format_backup=g:ag.format
    let g:ag.format="%f"
  elseif exists("s:ag_format_backup")
    let g:ag.format=s:ag_format_backup
  elseif !exists("g:ag.format")
    let g:ag.format="%f:%l:%c:%m"
  endif

  let l:grepprg_bak=&grepprg
  let l:grepformat_bak=&grepformat
  let l:t_ti_bak=&t_ti
  let l:t_te_bak=&t_te
  try
    let &grepprg=g:ag.prg
    let &grepformat=g:ag.format
    set t_ti=
    set t_te=
    if g:ag.working_path_mode ==? 'r' " Try to find the projectroot for current buffer
      let l:cwd_back = getcwd()
      let l:cwd = s:guessProjectRoot()
      try
        exe "lcd ".l:cwd
      catch
        echom 'Failed to change directory to:'.l:cwd
      finally
        silent! execute a:cmd . " " . escape(l:grepargs, '|')
        exe "lcd ".l:cwd_back
      endtry
    else " Someone chose an undefined value or 'c' so we revert to the default
      silent! execute a:cmd . " " . escape(l:grepargs, '|')
    endif
  finally
    let &grepprg=l:grepprg_bak
    let &grepformat=l:grepformat_bak
    let &t_ti=l:t_ti_bak
    let &t_te=l:t_te_bak
  endtry

  if a:cmd =~# '^l'
    let l:match_count = len(getloclist(winnr()))
  else
    let l:match_count = len(getqflist())
  endif

  if l:match_count
    if a:cmd =~# '^l'
      exe g:ag.lhandler
      let l:apply_mappings = g:ag.apply_lmappings
      let l:matches_window_prefix = 'l' " we're using the location list
    else
      exe g:ag.qhandler
      let l:apply_mappings = g:ag.apply_qmappings
      let l:matches_window_prefix = 'c' " we're using the quickfix window
    endif
  endif

  " If highlighting is on, highlight the search keyword.
  if exists('g:ag.highlight')
    let @/ = matchstr(a:args, "\\v(-)\@<!(\<)\@<=\\w+|['\"]\\zs.{-}\\ze['\"]")
    call feedkeys(":let &hlsearch=1 \| echo \<CR>", 'n')
  end

  redraw!

  if l:match_count
    if l:apply_mappings
      nnoremap <silent> <buffer> h  <C-W><CR><C-w>K
      nnoremap <silent> <buffer> H  <C-W><CR><C-w>K<C-w>b
      nnoremap <silent> <buffer> o  <CR>
      nnoremap <silent> <buffer> t  <C-w><CR><C-w>T
      nnoremap <silent> <buffer> T  <C-w><CR><C-w>TgT<C-W><C-W>
      nnoremap <silent> <buffer> v  <C-w><CR><C-w>H<C-W>b<C-W>J<C-W>t

      exe 'nnoremap <silent> <buffer> e <CR><C-w><C-w>:' . l:matches_window_prefix .'close<CR>'
      exe 'nnoremap <silent> <buffer> go <CR>:' . l:matches_window_prefix . 'open<CR>'
      exe 'nnoremap <silent> <buffer> q  :' . l:matches_window_prefix . 'close<CR>'

      exe 'nnoremap <silent> <buffer> gv :let b:height=winheight(0)<CR><C-w><CR><C-w>H:' . l:matches_window_prefix . 'open<CR><C-w>J:exe printf(":normal %d\<lt>c-w>_", b:height)<CR>'
      " Interpretation:
      " :let b:height=winheight(0)<CR>                      Get the height of the quickfix/location list window
      " <CR><C-w>                                           Open the current item in a new split
      " <C-w>H                                              Slam the newly opened window against the left edge
      " :copen<CR> -or- :lopen<CR>                          Open either the quickfix window or the location list (whichever we were using)
      " <C-w>J                                              Slam the quickfix/location list window against the bottom edge
      " :exe printf(":normal %d\<lt>c-w>_", b:height)<CR>   Restore the quickfix/location list window's height from before we opened the match

      if g:ag.mapping_message && l:apply_mappings
        echom "ag.vim keys: q=quit <cr>/e/t/h/v=enter/edit/tab/split/vsplit go/T/H/gv=preview versions of same"
      endif
    endif
  else " Close the split window automatically:
    cclose
    lclose
    echohl WarningMsg
    echom 'No matches for "'.a:args.'"'
    echohl None
  endif
endfunction

function! ag#AgFromSearch(cmd, args)
  let search =  getreg('/')
  " translate vim regular expression to perl regular expression.
  let search = substitute(search,'\(\\<\|\\>\)','\\b','g')
  call ag#Ag(a:cmd, '"' .  search .'" '. a:args)
endfunction

function! ag#GetDocLocations()
  let dp = ''
  for p in split(&runtimepath,',')
    let p = p.'doc/'
    if isdirectory(p)
      let dp = p.'*.txt '.dp
    endif
  endfor
  return dp
endfunction

function! ag#AgHelp(cmd,args)
  let args = a:args.' '.ag#GetDocLocations()
  call ag#Ag(a:cmd,args)
endfunction

function! s:guessProjectRoot()
  let l:splitsearchdir = split(getcwd(), "/")

  while len(l:splitsearchdir) > 2
    let l:searchdir = '/'.join(l:splitsearchdir, '/').'/'
    for l:marker in ['.rootdir', '.git', '.hg', '.svn', 'bzr', '_darcs', 'build.xml']
      " found it! Return the dir
      if filereadable(l:searchdir.l:marker) || isdirectory(l:searchdir.l:marker)
        return l:searchdir
      endif
    endfor
    let l:splitsearchdir = l:splitsearchdir[0:-2] " Splice the list to get rid of the tail directory
  endwhile

  " Nothing found, fallback to current working dir
  return getcwd()
endfunction
