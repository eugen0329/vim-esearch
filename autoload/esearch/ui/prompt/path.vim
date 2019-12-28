let s:Log        = esearch#log#import()
let s:PathPrompt = esearch#ui#component()

fu! s:PathPrompt.render() abort dict
  if !g:esearch#has#posix_shell
    return [[self.props.normal_highlight, esearch#shell#join(self.props.paths)]]
  endif
  if type(self.props.paths) ==# type({})
    return [['Special', self.props.paths.repr()]]
  endif

  let cwd = self.props.cwd
  let paths = self.props.paths
  let result = []
  let dir_icon = g:esearch#cmdline#dir_icon
  let end = len(paths) - 1
  for i in range(0, end)
    let path = paths[i]
    if path.raw
      let result += [['Special', path.str]]
    elseif isdirectory(esearch#util#abspath(cwd, path.str))
      let result += [['Directory', dir_icon . esearch#shell#escape(path)]]
    elseif empty(path.metachars)
      let result += [[self.props.normal_highlight, esearch#shell#escape(path)]]
    else
      let result += self.highlight_metachars(path)
    endif

    if i != end
      let result += [[self.props.normal_highlight, ', ']]
    endif
  endfor

  return result
endfu

fu! s:PathPrompt.highlight_metachars(path) abort dict
  let parts = esearch#shell#split_by_metachars(a:path)
  let result = []

  for regular_index in range(0, len(parts)-3, 2)
    let i = regular_index + 1
    let result += [[self.props.normal_highlight, parts[regular_index]]]
    let result += [['Identifier', parts[i]]]
  endfor

  let result += [[self.props.normal_highlight, parts[-1]]]
  return result
endfu

let s:PathPrompt.default_props = {'normal_highlight': 'NONE'}

let s:map_state_to_props = esearch#util#slice_factory(['cwd', 'paths'])

fu! esearch#ui#prompt#path#import() abort
  return esearch#ui#connect(s:PathPrompt, s:map_state_to_props)
endfu
