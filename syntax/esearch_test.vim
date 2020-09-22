if !hlexists('esearchHeader') | call esearch#highlight#init() | endif
syn match esearchLineNr     '^\s\s\s\+[+^_]\=\s*\d\+\s'
syn match esearchDiffAdd    '^\s\s\s\+\zs[+^_]' contained containedin=esearchLineNr
syn match esearchFilename   '^\s\s[^ ].*$'
syn match esearchHeader     '\s\sMatches.*'
syn match esearchStatistics '\d\+' contained containedin=esearchStatistics
