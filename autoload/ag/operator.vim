function! s:define(view, motion_wise)
  let beg = line("'[")
  let end = line("']")

  for n in range(beg, end)
    let _s = getline(n)
    let s = {
          \  "all":     _s,
          \  "between": _s[col("'[")-1 : col("']")-1],
          \  "pos2end": _s[col("'[")-1 : -1 ],
          \  "beg2pos": _s[ : col("']")-1],
          \  }

    if a:motion_wise == 'char'
      let str = ( beg == end ? s.between :
                \ n   == beg ? s.pos2end :
                \ n   == end ? s.beg2pos : s.all)
    elseif a:motion_wise == 'line'  | let str = s.all
    elseif a:motion_wise == 'block' | let str = s.between
    endif

    let str = '-Q "'.escape(str, '"').'"'
    if a:view ==# 'qf'
      call ag#Ag('grep', str)
    elseif a:view ==# 'loc'
      call ag#Ag('lgrep', str)
    elseif a:view ==# 'grp'
      call ag#AgGroup(0, 0, '', str)
    endif

  endfor
endfunction


let s:operators = ['qf', 'loc', 'grp']
for v in s:operators
  exe "fun! ag#operator#".v."(mw)\ncall s:define('".v."', a:mw)\nendf"
endfor


function! ag#operator#init()
  for v in s:operators
    call operator#user#define('ag-'.v, 'ag#operator#'.v)
  endfor
endfunction
