if !exists('g:esearch#cmdline#help_prompt')
  let g:esearch#cmdline#help_prompt = 1
endif

fu! esearch#help#cmdline(mappings, comments) abort
  let mappings = a:mappings
  let comments = a:comments
  let help_map = '<Plug>(esearch-cmdline-help)'

  for [m, plug] in items(mappings.without_val(help_map).dict())
    call esearch#util#hlecho([
          \ ['Title', printf('%10s:', esearch#util#stringify_mapping(m))],
          \ ['Normal', '  '.comments[plug]."\n"]])
  endfor

  let map = printf('%10s:', esearch#util#stringify_mapping(mappings.key(help_map)))
  call esearch#util#hlecho([ ['Title', map], ['Normal', '  '.comments[help_map]] ])

  if g:esearch#cmdline#help_prompt
    call esearch#util#hlecho([
          \['Normal',    "\n\nAdd `"],
          \['Statement', 'let '],
          \['Identifier', 'esearch#cmdline#help_prompt'],
          \['Operator', ' = '],
          \['Normal', '0` to '],
          \['Bold', '' ==# $MYVIMRC ? 'your vimrc' : $MYVIMRC],
          \['Normal', ' to disable help prompt']])
  endif
endfu

fu! esearch#help#backend_dependencies() abort
  " let plug_manager = esearch#util#recognize_plug_manager()
  let plug_manager = 'Pathogen'
  let plug_install = s:plug_install_cmd('Shougo/vimproc.vim', plug_manager)


  call esearch#util#hlecho([
        \['Error',    'To access async features, ESearch requires NeoVim job control or Vimproc plugin installed'],
        \['Normal', "\n"],
        \['Normal', 'Please, install NeoVim or ']]
        \ + plug_install +
        \[['Normal', "\n"],
        \['Normal', "See:\n\thttps://neovim.io/doc/user/job_control.html\n\thttps://github.com/Shougo/vimproc.vim"]
        \])
endfu

fu! s:plug_install_cmd(plug, manager) abort
  if a:manager ==# 'Pathogen'
    return [['Normal', 'execute'], ['Bold', '`cd ~/.vim/bundle && git clone https://github.com/Shougo/vimproc.vim`']]
  else

    let myvimrc = '' ==# $MYVIMRC ? 'your vimrc' : $MYVIMRC
    if a:manager =~? 'Plug\|Vundle\|NeoBundle'
      let cmds = { 'Plug': 'Plug', 'NeoBundle': 'NeoBundle', 'Vundle': 'Plugin' }
      let vimrc_cmd = [['Cleared', cmds[a:manager].' '], ['String', "'".a:plug."'"]]
    else " a:manager == 'Dein'
      let vimrc_cmd = [['Statement', 'call'],
            \ ['Cleared',   ' dein#add'],
            \ ['Delimiter', '('],
            \ ['String',    "'".a:plug."'"],
            \ ['Delimiter', ')']]
    endif

    return [['Normal', 'add `']] + vimrc_cmd + [['Normal', '` to '], ['Bold', myvimrc]]
  endif
endfu
