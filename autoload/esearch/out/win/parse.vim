let s:String = vital#esearch#import('Data.String')

let [s:true, s:false, s:null, s:t_dict, s:t_float, s:t_func,
      \ s:t_list, s:t_number, s:t_string] = esearch#polyfill#definitions()

fu! esearch#out#win#parse#entire() abort
  if line('$') < 3
    return {'contexts': {}}
  endif

  let header = getline(1)
  let blank_line = getline(2)

  if !s:String.starts_with(header, 'Matches in')  || !empty(blank_line)
    return {'error': 'The header is broken'}
  endif

  let line = 3
  let contexts = {}
  let current_context = s:null

  while line <= line('$')
    let text = getline(line)

    if text =~# '^[^ ]'
      if current_context isnot# s:null
        return {'error': 'Unexpected filename', 'line': line}
      endif

      let current_context = text
      let contexts[current_context] = {}
    elseif text =~# '^\s\+\d\+\s'
      if current_context is# s:null
        return {'error': 'Unexpected result line', 'line': line}
      endif

      let [line_number, text] = matchlist(text, '^\s\+\(\d\+\)\s\(.*\)')[1:2]
      let contexts[current_context][line_number] = text
    elseif empty(text)
      let current_context = s:null
    else
      throw text
    endif

    let line += 1
  endwhile

  return {'contexts': contexts}
endfu
