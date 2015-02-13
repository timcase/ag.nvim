" NOTE: You must, of course, install ag / the_silver_searcher

if exists('g:autoloaded_ag')
  finish
endif
let g:autoloaded_ag = 1

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
    let g:ag_prg="ag --vimgrep"
  else
    let g:ag_prg="ag --column"
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

  if a:cmd =~# '^l'
    let l:using_loclist = 1
  else
    let l:using_loclist = 0
  endif

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

  let l:grepprg_bak    = &l:grepprg
  let l:grepformat_bak = &grepformat
  let l:t_ti_bak       = &t_ti
  let l:t_te_bak       = &t_te

  try
    let &l:grepprg  = g:ag_prg
    let &grepformat = g:ag_format
    set t_ti=
    set t_te=
    silent! execute a:cmd . " " . escape(l:grepargs, '|')
  finally
    let &l:grepprg  = l:grepprg_bak
    let &grepformat = l:grepformat_bak
    let &t_ti       = l:t_ti_bak
    let &t_te       = l:t_te_bak
  endtry

  if l:using_loclist
    let l:match_count = len(getloclist(winnr()))
  else
    let l:match_count = len(getqflist())
  endif

  if l:using_loclist && l:match_count
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
    let @/=a:args
    set hlsearch
  end

  redraw!

  if l:match_count
    if l:apply_mappings
      nnoremap <buffer> <silent> h  <C-W><CR><C-w>K
      nnoremap <buffer> <silent> H  <C-W><CR><C-w>K<C-w>b
      nnoremap <buffer> <silent> o  <CR>
      nnoremap <buffer> <silent> t  <C-w><CR><C-w>T
      nnoremap <buffer> <silent> T  <C-w><CR><C-w>TgT<C-W><C-W>
      nnoremap <buffer> <silent> v  <C-w><CR><C-w>H<C-W>b<C-W>J<C-W>t

      let l:closecmd = l:matches_window_prefix . 'close'
      let l:opencmd  = l:matches_window_prefix . 'open'

      exe 'nnoremap <buffer> <silent> e <CR><C-w><C-w>:' . l:closecmd . '<CR>'
      exe 'nnoremap <buffer> <silent> go <CR>:' . l:opencmd . '<CR>'
      exe 'nnoremap <buffer> <silent> q :' . l:closecmd . '<CR>'

      exe 'nnoremap <buffer> <silent> gv :call <SID>PreviewVertical("' . l:opencmd . '")<CR>'

      if g:ag_mapping_message && l:apply_mappings
        echom "ag.vim keys: q=quit <cr>/e/t/h/v=enter/edit/tab/split/vsplit go/T/H/gv=preview versions of same"
      endif
    endif
  else
    echom 'No matches for "'.a:args.'"'
  endif
endfunction

function! ag#AgFromSearch(cmd, args)
  let search =  getreg('/')
  " translate vim regular expression to perl regular expression.
  let search = substitute(search,'\(\\<\|\\>\)','\\b','g')
  call ag#Ag(a:cmd, '"' .  search .'" '. a:args)
endfunction

function! ag#AgHelp(cmd,args)
  let args = a:args.' '.s:GetDocLocations()
  call ag#Ag(a:cmd,args)
endfunction

"-----------------------------------------------------------------------------
" Private API
"-----------------------------------------------------------------------------

function! s:GetDocLocations()
  let dp = ''
  for p in split(&runtimepath,',')
    let p = p.'/doc/'
    if isdirectory(p)
      let dp = p.'*.txt '.dp
    endif
  endfor
  return dp
endfunction

" Called from within a list window, preserves its height after shuffling vsplit.
" The parameter indicates whether list was opened as copen or lopen.
function! s:PreviewVertical(opencmd)
  let b:height = winheight(0)    " Get the height of list window
  exec "normal! \<C-w>\<CR>"   | " Open current item in a new split
  wincmd H                       " Slam newly opened window against the left edge
  exec a:opencmd               | " Move back to the list window
  wincmd J                       " Slam the list window against the bottom edge
  exec 'resize' b:height       | " Restore the list window's height
endfunction
