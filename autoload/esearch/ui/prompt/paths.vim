let s:Filepath = vital#esearch#import('System.Filepath')
let s:Message = esearch#message#import()

let s:PathsPrompt = esearch#ui#component()

fu! s:PathsPrompt.render() abort dict
  if self.props.cwd ==# getcwd() && empty(self.props.paths)
    return []
  endif

  return self.render_in(self.props.paths, self.props.metadata)
        \ + self.print_paths(self.props.paths, self.props.metadata)
endfu

fu! s:PathsPrompt.render_in(paths, metadata) abort
  let path_kinds = {}
  for i in range(0, len(a:paths) - 1)
    if isdirectory(a:paths[i])
      let path_kinds['directory'] = 1
    elseif !empty(a:metadata) || !filereadable(a:paths[i])
      let path_kinds['path'] = 1
    else
      let path_kinds['file'] = 1
    endif

    if len(path_kinds) > 1
      return [['NONE', 'In ']]
    endif
  endfor

  let where = 'In ' . esearch#inflector#pluralize(keys(path_kinds)[0], len(a:paths)) . ' '
  return [['NONE', where]]
endfu

fu! s:PathsPrompt.print_paths(paths, metadata) abort dict
  let metadata = a:metadata
  let paths = a:paths
  let end = len(paths) - 1
  let result = []
  let dir_icon = g:esearch#cmdline#dir_icon

  for i in range(0, end)
    let path = paths[i]

    if isdirectory(paths[i])
      let result += [['Directory', dir_icon . esearch#shell#fnameescape(paths[i])]]
    elseif empty(metadata) || empty(metadata[i].wildcards)
      let result += [['NONE', esearch#shell#fnameescape(paths[i])]]
    else
      let result += self.highlight_special_chars(path, metadata[i])
    endif

    if i != end
      let result += [['NONE', ', ']]
    endif
  endfor

  return result
endfu

fu! s:PathsPrompt.highlight_special_chars(path, metadata) abort dict
  let parts = esearch#shell#fnameescape_splitted(a:path, a:metadata)
  let result = []

  for regular_index in range(0, len(parts)-3, 2)
    let special_index = regular_index + 1
    let result += [['NONE', parts[regular_index]]]
    let result += [['Identifier', parts[special_index]]]
  endfor

  let result += [['NONE', parts[-1]]]
  return result
endfu

let s:map_state_to_props = esearch#util#slice_factory(['cwd', 'paths', 'metadata'])

fu! esearch#ui#prompt#paths#import() abort
  return esearch#ui#connect(s:PathsPrompt, s:map_state_to_props)
endfu
