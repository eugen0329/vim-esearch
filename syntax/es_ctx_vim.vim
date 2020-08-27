if exists('b:current_syntax')
  finish
endif

" Mostly focused on commands that usually appear within vimrc
syn keyword es_vimCommand if el[seif] en[dif] for endfo[r] sil[ent] fu[nction] retu[rn] endf[unction] wh[ile] endw[hile] try th[row] cat[ch] fina[lly] endt[ry] fina[lly] sy[ntax] setf[iletype] cal[l] com[mand] au[tocmd] do[autocmd] doautoa[ll] aug[roup] ec[hoerr] exe[cute] hi[ghlight] redi[r] hi[ghlight] let unl[et]
syn keyword es_VimCommand cm[ap] cmapc[lear] cno[remap] cu[nmap] im[ap] imapc[lear] ino[remap] iu[nmap] lm[ap] lmapc[lear] ln[oremap] lu[nmap] map mapc[lear] nm[ap] nmapc[lear] nn[oremap] no[remap] nun[map] om[ap] omapc[lear] ono[remap] ou[nmap] sm[ap] smap smapc[lear] snor[emap] sunm[ap] tma[p] tmapc[lear] tno[remap] tunma[p] unm[ap] vm[ap] vmapc[lear] vn[oremap] vu[nmap] xm[ap] xmapc[lear] xn[oremap] xu[nmap] ab[breviate] abc[lear] ca[bbrev] cabc[lear] cnorea[bbrev] cuna[bbrev] ia[bbrev] iabc[lear] inorea[bbrev] iuna[bbrev] norea[bbrev] una[bbreviate]

 " es_vimVarAssignment
syn match  es_vimCommand   /\<se\%[tlocal]\>/ skipwhite nextgroup=es_vimOption
syn match  es_vimOption    "\w\+" contained
syn match  es_vimVar       "\<[bwglstav]:\h[a-zA-Z0-9#_]*"

syn match  es_vimFunction  "\%(\<[bwglstav]:\)\=\h[a-zA-Z0-9#_]*\ze("
syn match  es_vimFuncName  "[^.]\zs\<[_0-9a-z]\+\ze("
syn region es_vimString    start=+"+ skip=+\\\\\|\\"+ end=+"\|^+
syn region es_vimString    start=+'+ end=+'\|^+
syn match  es_vimComment   +\s"[^\-:.%#=*].*[^"]$+lc=1

hi def link es_vimCommand  Statement
hi def link es_vimVar      Identifier
hi def link es_vimFuncName Function
hi def link es_vimString   String
hi def link es_vimComment  Comment
hi def link es_vimOption   PreProc

let b:current_syntax = 'es_ctx_vim'
