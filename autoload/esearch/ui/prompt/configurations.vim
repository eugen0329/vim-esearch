let s:Filepath = vital#esearch#import('System.Filepath')
let s:List = vital#esearch#import('Data.List')
let s:String = vital#esearch#import('Data.String')
let s:Log = esearch#log#import()
let s:FiletypePrompt = esearch#ui#prompt#filetype#import()
let s:PathPrompt = esearch#ui#prompt#path#import()

let s:ConfigurationsPrompt = esearch#ui#component()

fu! s:ConfigurationsPrompt.render() abort dict
  let result = s:FiletypePrompt.new().render() 

  let [absolute_paths, relative_paths] = s:List.partition(function('s:is_abspath'), self.props.paths)

  if self.props.cwd ==# getcwd()
    let result += s:PathPrompt.new({'paths': relative_paths}).render()
  else
    let result += [['Directory', g:esearch#cmdline#dir_icon . s:Filepath.relpath(self.props.cwd)]]

    let relative_paths = s:PathPrompt.new({'paths': relative_paths, 'separator': ', '}).render()
    if !empty(relative_paths)
      let result += [[self.props.normal_hl, '/{ ']] + relative_paths + [[self.props.normal_hl, ' }']]
    endif
  endif

  if !empty(result) | let result += [[self.props.normal_hl, ' ']] | endif
  let result += s:PathPrompt.new({'paths': absolute_paths}).render()

  return empty(result) ? [] : [[self.props.normal_hl, 'In ']] + result
endfu

fu! s:is_abspath(path) abort
  return esearch#util#is_abspath(a:path.str)
endfu

let s:ConfigurationsPrompt.default_props = {'normal_hl': 'NONE'}
let s:map_state_to_props = esearch#util#slice_factory(['cwd', 'paths', 'filetypes'])

fu! esearch#ui#prompt#configurations#import() abort
  return esearch#ui#connect(s:ConfigurationsPrompt, s:map_state_to_props)
endfu
