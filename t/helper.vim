let $PJROOT = fnamemodify(resolve(expand('<sfile>')), ':h:h')
let $VADERT = expand($PJROOT .'/t/vader.vim/')

set runtimepath+=$VADERT
exe 'so' fnameescape($VADERT . '/plugin/vader.vim')

set runtimepath+=$PJROOT
exe 'so' fnameescape($PJROOT . '/plugin/ag.vim')
