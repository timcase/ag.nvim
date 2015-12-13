function! ag#qf#search(cmd, args)
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

  call ag#qf#exec(a:cmd, l:grepargs)

  if a:cmd =~# '^l'
    let l:match_count = len(getloclist(winnr()))
  else
    let l:match_count = len(getqflist())
  endif

  if l:match_count
    if a:cmd =~# '^l'
      exe g:ag.lhandler
      let b:ag_apply_mappings = g:ag.apply_lmappings
      let b:ag_win_prefix = 'l' " we're using the location list
    else
      exe g:ag.qhandler
      let b:ag_apply_mappings = g:ag.apply_qmappings
      let b:ag_win_prefix = 'c' " we're using the quickfix window
    endif
    setfiletype qf
  endif

  " If highlighting is on, highlight the search keyword.
  if exists('g:ag.highlight')
    let @/ = matchstr(a:args, "\\v(-)\@<!(\<)\@<=\\w+|['\"]\\zs.{-}\\ze['\"]")
    call feedkeys(":let &hlsearch=1 \| echo \<CR>", 'n')
  end

  redraw!

  if l:match_count && b:ag_apply_mappings && g:ag.mapping_message
    echom "ag.vim keys: q=quit <cr>/e/t/h/v=enter/edit/tab/split/vsplit go/T/H/gv=preview versions of same"
  endif

  if !l:match_count
    " Close the split window automatically:
    cclose
    lclose
    echohl WarningMsg
    echom 'No matches for "'.a:args.'"'
    echohl None
  endif
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


function! ag#qf#exec(cmd, args)
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
        silent! execute a:cmd . " " . escape(a:args, '|')
        exe "lcd ".l:cwd_back
      endtry
    else " Someone chose an undefined value or 'c' so we revert to the default
      silent! execute a:cmd . " " . escape(a:args, '|')
    endif
  finally
    let &grepprg=l:grepprg_bak
    let &grepformat=l:grepformat_bak
    let &t_ti=l:t_ti_bak
    let &t_te=l:t_te_bak
  endtry
endfunction
