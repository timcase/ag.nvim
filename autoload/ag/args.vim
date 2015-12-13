function! ag#args#slash(cmd, args)
  let search =  getreg('/')
  " translate vim regular expression to perl regular expression.
  let search = substitute(search,'\(\\<\|\\>\)','\\b','g')
  call ag#Ag(a:cmd, '"' .  search .'" '. a:args)
endfunction
