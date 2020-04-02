let s:Filepath   = vital#esearch#import('System.Filepath')
let s:Message    = esearch#message#import()
let s:PathPrompt = esearch#ui#component()

fu! s:PathPrompt.render() abort dict
  let metadata = self.props.metadata
  let paths = self.props.paths
  let end = len(paths) - 1
  let result = []
  let dir_icon = g:esearch#cmdline#dir_icon

  for i in range(0, end)
    let path = paths[i]

    if isdirectory(paths[i])
      let result += [['Directory', dir_icon . esearch#shell#fnameescape(paths[i])]]
    elseif empty(metadata) || empty(metadata[i].wildcards)
      let result += [[self.props.normal_highlight, esearch#shell#fnameescape(paths[i])]]
    else
      let result += self.highlight_special_chars(path, metadata[i])
    endif

    if i != end
      let result += [[self.props.normal_highlight, ', ']]
    endif
  endfor

  return result
endfu

fu! s:PathPrompt.highlight_special_chars(path, metadata) abort dict
  let parts = esearch#shell#fnameescape_splitted(a:path, a:metadata)
  let result = []

  for regular_index in range(0, len(parts)-3, 2)
    let special_index = regular_index + 1
    let result += [[self.props.normal_highlight, parts[regular_index]]]
    let result += [['Identifier', parts[special_index]]]
  endfor

  let result += [[self.props.normal_highlight, parts[-1]]]
  return result
endfu

let s:PathPrompt.default_props = {'normal_highlight': 'NONE'}

let s:map_state_to_props = esearch#util#slice_factory(['cwd', 'paths', 'metadata'])

fu! esearch#ui#prompt#path#import() abort
  return esearch#ui#connect(s:PathPrompt, s:map_state_to_props)
endfu
