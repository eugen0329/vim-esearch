fu! esearch#out#win#parse#entire() abort
  if line('$') < 3 | return {'ctx_by_name': {}} | endif

  let ctx_by_name = {}
  let ctx = {}
  let lnum = 3
  let buflines = [''] + getline(1, '$')
  while lnum <= line('$')
    let text = buflines[lnum]

    if text =~# '^[^ ]'
      if !empty(ctx) | return {'error': 'Unexpected filename', 'line': lnum} | endif

      let ctx = {'lines': {}, 'lnums': []}
      let ctx_by_name[text] = ctx
    elseif text =~# '^\s\+[v^]\=\d\+\s'
      if empty(ctx) | return {'error': 'Unexpected entry', 'line': lnum} | endif

      let [file_lnum, text] = matchlist(text, '^\s\+[v^]\=\(\d\+\)\s\(.*\)')[1:2]
      let ctx.lines[file_lnum] = get(ctx.lines, file_lnum, []) + [text]
      let ctx.lnums += [file_lnum]
    elseif empty(text)
      let ctx = {}
    else
      throw text
    endif

    let lnum += 1
  endwhile

  return {'ctx_by_name': ctx_by_name}
endfu
