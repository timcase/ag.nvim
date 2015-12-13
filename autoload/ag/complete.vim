fun! ag#complete#file_fuzzy(arg, line, pos)
  let l = split(a:line[:a:pos-1], '\v%(%(%(^|[^\\])\\)@<!\s)+', 1)
  let n = len(l) - match(l, 'L\?Ag') - 1
  let cmd = g:ag.bin." -S -g '".shellescape(a:arg)."'"
  if n>1 | return systemlist(l:cmd) | endif
endfun
