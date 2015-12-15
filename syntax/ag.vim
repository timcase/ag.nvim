"" Syntax highlight for AgGroup results
if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

hi def link agLine LineNr
hi def link agFile Question
hi def link agSearch Todo
hi def link agLineContext Constant

if b:ignore_case
  syn case ignore
endif

syn match agLine /^\d\+:\d\+:/ conceal
syn match agLineContext /^\d\+-/ conceal
syn match agFile /^\n.\+$/hs=s+1


silent syn clear agSearch
try
  try
    execute 'syn match agSearch /\v'.b:pattern.'/'
  catch /^Vim\%((\a\+)\)\=:E54/ " invalid regexp
      execute 'syn match agSearch /'.b:pattern.'/'
  endtry
catch
endtry
