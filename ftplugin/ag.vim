highlight link agLine LineNr
highlight link agFile Question
highlight link agSearch Todo
highlight link agLineContext Constant

setlocal foldmethod=expr
setlocal foldexpr=ag#ctrl#FoldAg()
setlocal foldcolumn=2
1
setlocal nomodifiable

noremap <silent> <buffer> o       zaj
noremap <silent> <buffer> <Space> :call ag#ctrl#NextFold()<CR>
noremap <silent> <buffer> O       :call ag#ctrl#ToggleEntireFold()<CR>
noremap <silent> <buffer> <CR>    :call ag#ctrl#OpenFile(0)<CR>
noremap <silent> <buffer> s       :call ag#ctrl#OpenFile(1)<CR>
noremap <silent> <buffer> S       :call ag#ctrl#OpenFile(2)<CR>
noremap <silent> <buffer> d       :call ag#ctrl#DeleteFold()<CR>
noremap <silent> <buffer> gl      :call ag#ctrl#ToggleShowLine()<CR>
