let s:Filepath   = vital#esearch#import('System.Filepath')
let s:Message    = esearch#message#import()
let s:PathPrompt = esearch#ui#prompt#path#import()

let s:PathTitlePrompt = esearch#ui#component()

fu! s:PathTitlePrompt.render() abort dict
  if self.props.cwd ==# getcwd() && empty(self.props.paths)
    return []
  endif

  return self.render_in(self.props.paths, self.props.metadata)
        \ + s:PathPrompt.new({}).render()
endfu

fu! s:PathTitlePrompt.render_in(paths, metadata) abort dict
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
      return [[self.props.normal_highlight, 'In ']]
    endif
  endfor

  let where = 'In ' . esearch#util#pluralize(keys(path_kinds)[0], len(a:paths)) . ' '
  return [[self.props.normal_highlight, where]]
endfu

let s:PathTitlePrompt.default_props = {'normal_highlight': 'NONE'}

let s:map_state_to_props = esearch#util#slice_factory(['cwd', 'paths', 'metadata'])

fu! esearch#ui#prompt#path_title#import() abort
  return esearch#ui#connect(s:PathTitlePrompt, s:map_state_to_props)
endfu
