" NOTE: You must, of course, install ag / the_silver_searcher

" FIXME: Delete deprecated options below on or after 15-7 (6 months from when they were changed) {{{

if exists("g:agprg")
  let g:ag_prg = g:agprg
endif

if exists("g:aghighlight")
  let g:ag_highlight = g:aghighlight
endif

if exists("g:agformat")
  let g:ag_format = g:agformat
endif

" }}} FIXME: Delete the deprecated options above on or after 15-7 (6 months from when they were changed)

" Location of the ag utility
if !exists("g:ag_prg")
  " --vimgrep (consistent output we can parse) is available from version  0.25.0+
  if split(system("ag --version"), "[ \n\r\t]")[2] =~ '\d\+.[2-9][5-9]\(.\d\+\)\?'
    let g:ag_prg="ag --vimgrep --silent"
  else
    " --noheading seems odd here, but see https://github.com/ggreer/the_silver_searcher/issues/361
    let g:ag_prg="ag --column --nogroup --noheading"
  endif
endif

if !exists("g:ag_apply_qmappings")
  let g:ag_apply_qmappings=1
endif

if !exists("g:ag_apply_lmappings")
  let g:ag_apply_lmappings=1
endif

if !exists("g:ag_qhandler")
  let g:ag_qhandler="botright copen"
endif

if !exists("g:ag_lhandler")
  let g:ag_lhandler="botright lopen"
endif

if !exists("g:ag_mapping_message")
  let g:ag_mapping_message=1
endif

if !exists("g:ag_working_path_mode")
    let g:ag_working_path_mode = 'c'
endif

" Variables required to manage async
let s:job_number = 0
let s:cmd = ''
let s:args = ''
let s:cwd = getcwd()
let s:data = []

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
  let l:ag_executable = get(split(g:ag_prg, " "), 0)

  " Ensure that `ag` is installed
  if !executable(l:ag_executable)
    echoe "Ag command '" . l:ag_executable . "' was not found. Is the silver searcher installed and on your $PATH?"
    return
  endif

  " If no pattern is provided, search for the word under the cursor
  if empty(a:args)
    let l:grepargs = expand("<cword>")
  else
    let l:grepargs = a:args . join(a:000, ' ')
  end

  " Format, used to manage column jump
  if a:cmd =~# '-g$'
    let s:ag_format_backup=g:ag_format
    let g:ag_format="%f"
  elseif exists("s:ag_format_backup")
    let g:ag_format=s:ag_format_backup
  elseif !exists("g:ag_format")
    let g:ag_format="%f:%l:%c:%m"
  endif

  " Set the script variables that will later be used by the async callback
  let s:args = a:args
  let s:cmd = a:cmd . " " . escape(l:grepargs, '|')

  let l:grepprg_bak=&grepprg
  let l:grepformat_bak=&grepformat
  let l:t_ti_bak=&t_ti
  let l:t_te_bak=&t_te
  try
    let &grepprg=g:ag_prg
    let &grepformat=g:ag_format
    set t_ti=
    set t_te=
    if g:ag_working_path_mode ==? 'r' " Try to find the projectroot for current buffer
      let l:cwd_back = getcwd()
      let s:cwd = s:guessProjectRoot()
      try
        exe "lcd ".s:cwd
      catch
      finally
        call s:executeCmd(l:grepargs)
        exe "lcd ".l:cwd_back
      endtry
    else " Someone chose an undefined value or 'c' so we revert to the default
      call s:executeCmd(l:grepargs)
    endif
  finally
    let &grepprg=l:grepprg_bak
    let &grepformat=l:grepformat_bak
    let &t_ti=l:t_ti_bak
    let &t_te=l:t_te_bak
  endtry

  " No neovim, when we finally get here we already have the output so run handleOutput
  if !has('nvim')
    call s:handleOutput()
    return
  endif
endfunction

function! s:handleOutput()
  if s:cmd =~# '^l'
    let l:match_count = len(getloclist(winnr()))
  else
    let l:match_count = len(getqflist())
  endif

  if s:cmd =~# '^l' && l:match_count
    exe g:ag_lhandler
    let l:apply_mappings = g:ag_apply_lmappings
    let l:matches_window_prefix = 'l' " we're using the location list
  elseif l:match_count
    exe g:ag_qhandler
    let l:apply_mappings = g:ag_apply_qmappings
    let l:matches_window_prefix = 'c' " we're using the quickfix window
  endif

  " If highlighting is on, highlight the search keyword.
  if exists("g:ag_highlight")
    let @/=s:args
    set hlsearch
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

      if g:ag_mapping_message && l:apply_mappings
        echom "ag.vim keys: q=quit <cr>/e/t/h/v=enter/edit/tab/split/vsplit go/T/H/gv=preview versions of same"
      endif
    endif
  else
    echom "No matches for '".s:args."'"
  endif
endfunction

function! s:handleAsyncOutput(job_id, data, event)
  " Don't care about older async calls that have been killed or replaced
  if s:job_number !=# a:job_id
    return
  end

  " Store all the input we get from the shell
  if a:event ==# 'stdout'
    let s:data = s:data+a:data

  " When the program has finished running we parse the data
  elseif a:event ==# 'exit'
    echom "Ag search finished"
    let l:expandeddata = []
    " Expand the path of the result so we can jump to it
    for result in s:data
      call add(l:expandeddata, s:cwd.'/'.result)
    endfor

    if len(l:expandeddata) " Only if we actually find something

      " Todo check if this empty last element always exists or not
      " Splice the last element of our list when it's a non-find
      if l:expandeddata[-1] =~? '\/\/$'
        let l:expandeddata = l:expandeddata[0:-2]
      endif

      if s:cmd =~# '^l'
        " Add to location list
        lgete l:expandeddata
      else
        " Add to quickfix list
        cgete l:expandeddata
      endif
      call s:handleOutput()
    else
      echom "No matches for '".s:args."'"
    endif
  endif
endfunction

function! s:executeCmd(grepargs)
  if !has('nvim')
    silent! execute s:cmd
    return
  endif

  " Stop older running ag jobs if any
  try
    call jobstop(s:job_number)
  catch
  endtry

  " Clear all of the old captures
  let s:data = []

  " All types of exiting the job should be directed to handleAsyncOutput
  let s:callbacks = {
  \ 'on_stdout': function('s:handleAsyncOutput'),
  \ 'on_stderr': function('s:handleAsyncOutput'),
  \ 'on_exit': function('s:handleAsyncOutput')
  \ }

  " Construct the command string send to job shell - cd [directory]; ag --vimgrep [value]
  let l:agcmd = "cd ".s:cwd."; ".g:ag_prg . " " .  escape(a:grepargs, '|')

  echom 'Ag search started'
  let s:job_number = jobstart(['sh', '-c', l:agcmd], extend({'shell': 'shell 1'}, s:callbacks))
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
    let p = p.'/doc/'
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
