let s:ag = {}
let s:ag.bin = 'ag'
let s:ag.ver = get(split(system(s:ag.bin.' --version'), "\_s"), 2, '')

" --vimgrep (consistent output we can parse) is available from v0.25.0+
let s:ag.prg = s:ag.bin . (s:ag.ver =~ '\v0\.%(\d|1\d|2[0-4])%(.\d+)?' ?
      \ ' --vimgrep' : ' --column')

let s:ag.last = {}
let s:ag.qhandler = "botright copen"
let s:ag.lhandler = "botright lopen"
let s:ag.nhandler = "botright new"
let s:ag.apply_qmappings = 1
let s:ag.apply_lmappings = 1
let s:ag.mapping_message = 1
let s:ag.goto_exact_line = 0
let s:ag.mappings_to_cmd_history = 0
let s:ag.working_path_mode = 'c'
let s:ag.root_markers = ['.rootdir', '.git/', '.hg/', '.svn/', 'bzr', '_darcs', 'build.xml']



function! ag#opts#init()
  let g:ag = extend(get(g:, 'ag', {}), s:ag, 'keep')
  if !executable(g:ag.bin)
    throw "Binary '".g:ag.bin."' was not found in your $PATH. "
        \."Check if the_silver_searcher is installed and available."
  endif
endfunction
