let s:Filepath   = vital#esearch#import('System.Filepath')
let s:Log        = esearch#log#import()
let s:PathPrompt = esearch#ui#prompt#path#import()

let s:PathTitlePrompt = esearch#ui#component()

" Is rendered above the search input

fu! s:PathTitlePrompt.render() abort dict
  if empty(self.props.paths)
    if self.props.cwd ==# getcwd()
      return []
    else
      return [
            \  [self.props.normal_highlight, 'In '],
            \  ['Directory', g:esearch#cmdline#dir_icon . s:Filepath.relpath(self.props.cwd)],
            \]
    endif
  endif

  return [[self.props.normal_highlight, 'In ']]
        \ + s:PathPrompt.new().render()
endfu

let s:PathTitlePrompt.default_props = {'normal_highlight': 'NONE'}
let s:map_state_to_props = esearch#util#slice_factory(['cwd', 'paths'])

fu! esearch#ui#prompt#path_title#import() abort
  return esearch#ui#connect(s:PathTitlePrompt, s:map_state_to_props)
endfu
