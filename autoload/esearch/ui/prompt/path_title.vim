let s:Filepath   = vital#esearch#import('System.Filepath')
let s:Message    = esearch#message#import()
let s:PathPrompt = esearch#ui#prompt#path#import()

let s:PathTitlePrompt = esearch#ui#component()

" Is rendered above the search input

fu! s:PathTitlePrompt.render() abort dict
  if empty(self.props.paths)
    if self.props.cwd ==# getcwd()
      return []
    else
      return  [
            \   [self.props.normal_highlight, 'In '],
            \   ['Directory', g:esearch#cmdline#dir_icon . s:Filepath.relpath(self.props.cwd)],
            \ ]
    endif
  endif

  return self.render_in(self.props.paths)
        \ + s:PathPrompt.new().render()
endfu

fu! s:PathTitlePrompt.render_in(paths) abort dict
  let cwd = self.props.cwd

  let path_kinds = {}

  for path in a:paths
    let path_str = esearch#util#abspath(cwd, path.str)

    if isdirectory(path_str)
      let path_kinds['directory'] = 1
    elseif !empty(path.metachars) || !filereadable(path_str)
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

let s:map_state_to_props = esearch#util#slice_factory(['cwd', 'paths'])

fu! esearch#ui#prompt#path_title#import() abort
  return esearch#ui#connect(s:PathTitlePrompt, s:map_state_to_props)
endfu
