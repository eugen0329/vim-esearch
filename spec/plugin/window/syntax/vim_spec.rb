# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'vim' do
    let(:source_file_content) do
      <<~SOURCE
        if
        for
        try
        let
        map
        smap

        el
        en
        endfo
        sil
        fu
        retu
        endf
        wh
        endw
        th
        cat
        fina
        endt
        fina
        sy
        setf
        unl
        cal
        com
        au
        do
        doautoa
        aug
        ec
        exe
        hi
        redi
        hi
        cm
        cmapc
        cno
        cu
        im
        imapc
        ino
        iu
        lm
        lmapc
        ln
        lu
        mapc
        nm
        nmapc
        nn
        no
        nun
        om
        omapc
        ono
        ou
        sm
        smapc
        snor
        sunm
        tma
        tmapc
        tno
        tunma
        unm
        vm
        vmapc
        vn
        vu
        xm
        xmapc
        xn
        xu
        ab
        abc
        ca
        cabc
        cnorea
        cuna
        ia
        iabc
        inorea
        iuna
        norea
        una

        elseif
        endif
        endfor
        silent
        function
        return
        endfunction
        while
        endwhile
        throw
        catch
        finally
        endtry
        finally
        syntax
        setfiletype
        unlet
        call
        command
        autocmd
        doautocmd
        doautoall
        augroup
        echoerr
        execute
        highlight
        redir
        highlight
        cmap
        cmapclear
        cnoremap
        cunmap
        imap
        imapclear
        inoremap
        iunmap
        lmap
        lmapclear
        lnoremap
        lunmap
        mapclear
        nmap
        nmapclear
        nnoremap
        noremap
        nunmap
        omap
        omapclear
        onoremap
        ounmap
        smap
        smapclear
        snoremap
        sunmap
        tmap
        tmapclear
        tnoremap
        tunmap
        unmap
        vmap
        vmapclear
        vnoremap
        vunmap
        xmap
        xmapclear
        xnoremap
        xunmap
        abbreviate
        abclear
        cabbrev
        cabclear
        cnoreabbrev
        cunabbrev
        iabbrev
        iabclear
        inoreabbrev
        iunabbrev
        noreabbrev
        unabbreviate

        set      backspace=
        setl     backspace=
        setlocal backspace=

        b:var_Var1
        w:var_Var2
        g:var_Var3
        l:var_Var4
        s:var_Var5
        t:var_Var6
        a:var_Var7
        v:var_Var8

        b:var#var
        w:var#var
        g:var#var
        l:var#var
        s:var#var
        t:var#var
        a:var#var
        v:var#var

        call eval()
        call sha256()
        if !eval()
        if ==eval()
        if =~eval()
        if 1-eval()
        call Function()

        call eval() " comment
        function s:name() " comment
        call self.name()

        if var ==# "string"
        if var ==# "missing quote
        if var ==# "escaped quote\\"
        if var ==# 'missing quote
        if var ==# 'escaped quote\\'
        if var ==# 'string'

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.vim') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('if')                    => %w[es_vimCommand Statement],
        word('for')                   => %w[es_vimCommand Statement],
        word('try')                   => %w[es_vimCommand Statement],
        word('let')                   => %w[es_vimCommand Statement],
        word('map')                   => %w[es_vimCommand Statement],
        word('smap')                  => %w[es_vimCommand Statement],

        # short
        word('el')                    => %w[es_vimCommand Statement],
        word('en')                    => %w[es_vimCommand Statement],
        word('endfo')                 => %w[es_vimCommand Statement],
        word('sil')                   => %w[es_vimCommand Statement],
        word('fu')                    => %w[es_vimCommand Statement],
        word('retu')                  => %w[es_vimCommand Statement],
        word('endf')                  => %w[es_vimCommand Statement],
        word('wh')                    => %w[es_vimCommand Statement],
        word('endw')                  => %w[es_vimCommand Statement],
        word('th')                    => %w[es_vimCommand Statement],
        word('cat')                   => %w[es_vimCommand Statement],
        word('fina')                  => %w[es_vimCommand Statement],
        word('endt')                  => %w[es_vimCommand Statement],
        word('fina')                  => %w[es_vimCommand Statement],
        word('sy')                    => %w[es_vimCommand Statement],
        word('setf')                  => %w[es_vimCommand Statement],
        word('unl')                   => %w[es_vimCommand Statement],
        word('cal')                   => %w[es_vimCommand Statement],
        word('com')                   => %w[es_vimCommand Statement],
        word('au')                    => %w[es_vimCommand Statement],
        word('do')                    => %w[es_vimCommand Statement],
        word('doautoa')               => %w[es_vimCommand Statement],
        word('aug')                   => %w[es_vimCommand Statement],
        word('ec')                    => %w[es_vimCommand Statement],
        word('exe')                   => %w[es_vimCommand Statement],
        word('hi')                    => %w[es_vimCommand Statement],
        word('redi')                  => %w[es_vimCommand Statement],
        word('hi')                    => %w[es_vimCommand Statement],
        word('cm')                    => %w[es_vimCommand Statement],
        word('cmapc')                 => %w[es_vimCommand Statement],
        word('cno')                   => %w[es_vimCommand Statement],
        word('cu')                    => %w[es_vimCommand Statement],
        word('im')                    => %w[es_vimCommand Statement],
        word('imapc')                 => %w[es_vimCommand Statement],
        word('ino')                   => %w[es_vimCommand Statement],
        word('iu')                    => %w[es_vimCommand Statement],
        word('lm')                    => %w[es_vimCommand Statement],
        word('lmapc')                 => %w[es_vimCommand Statement],
        word('ln')                    => %w[es_vimCommand Statement],
        word('lu')                    => %w[es_vimCommand Statement],
        word('mapc')                  => %w[es_vimCommand Statement],
        word('nm')                    => %w[es_vimCommand Statement],
        word('nmapc')                 => %w[es_vimCommand Statement],
        word('nn')                    => %w[es_vimCommand Statement],
        word('no')                    => %w[es_vimCommand Statement],
        word('nun')                   => %w[es_vimCommand Statement],
        word('om')                    => %w[es_vimCommand Statement],
        word('omapc')                 => %w[es_vimCommand Statement],
        word('ono')                   => %w[es_vimCommand Statement],
        word('ou')                    => %w[es_vimCommand Statement],
        word('sm')                    => %w[es_vimCommand Statement],
        word('smapc')                 => %w[es_vimCommand Statement],
        word('snor')                  => %w[es_vimCommand Statement],
        word('sunm')                  => %w[es_vimCommand Statement],
        word('tma')                   => %w[es_vimCommand Statement],
        word('tmapc')                 => %w[es_vimCommand Statement],
        word('tno')                   => %w[es_vimCommand Statement],
        word('tunma')                 => %w[es_vimCommand Statement],
        word('unm')                   => %w[es_vimCommand Statement],
        word('vm')                    => %w[es_vimCommand Statement],
        word('vmapc')                 => %w[es_vimCommand Statement],
        word('vn')                    => %w[es_vimCommand Statement],
        word('vu')                    => %w[es_vimCommand Statement],
        word('xm')                    => %w[es_vimCommand Statement],
        word('xmapc')                 => %w[es_vimCommand Statement],
        word('xn')                    => %w[es_vimCommand Statement],
        word('xu')                    => %w[es_vimCommand Statement],
        word('ab')                    => %w[es_vimCommand Statement],
        word('abc')                   => %w[es_vimCommand Statement],
        word('ca')                    => %w[es_vimCommand Statement],
        word('cabc')                  => %w[es_vimCommand Statement],
        word('cnorea')                => %w[es_vimCommand Statement],
        word('cuna')                  => %w[es_vimCommand Statement],
        word('ia')                    => %w[es_vimCommand Statement],
        word('iabc')                  => %w[es_vimCommand Statement],
        word('inorea')                => %w[es_vimCommand Statement],
        word('iuna')                  => %w[es_vimCommand Statement],
        word('norea')                 => %w[es_vimCommand Statement],
        word('una')                   => %w[es_vimCommand Statement],

        # long
        word('elseif')                => %w[es_vimCommand Statement],
        word('endif')                 => %w[es_vimCommand Statement],
        word('endfor')                => %w[es_vimCommand Statement],
        word('silent')                => %w[es_vimCommand Statement],
        word('function')              => %w[es_vimCommand Statement],
        word('return')                => %w[es_vimCommand Statement],
        word('endfunction')           => %w[es_vimCommand Statement],
        word('while')                 => %w[es_vimCommand Statement],
        word('endwhile')              => %w[es_vimCommand Statement],
        word('throw')                 => %w[es_vimCommand Statement],
        word('catch')                 => %w[es_vimCommand Statement],
        word('finally')               => %w[es_vimCommand Statement],
        word('endtry')                => %w[es_vimCommand Statement],
        word('finally')               => %w[es_vimCommand Statement],
        word('syntax')                => %w[es_vimCommand Statement],
        word('setfiletype')           => %w[es_vimCommand Statement],
        word('unlet')                 => %w[es_vimCommand Statement],
        word('call')                  => %w[es_vimCommand Statement],
        word('command')               => %w[es_vimCommand Statement],
        word('autocmd')               => %w[es_vimCommand Statement],
        word('doautocmd')             => %w[es_vimCommand Statement],
        word('doautoall')             => %w[es_vimCommand Statement],
        word('augroup')               => %w[es_vimCommand Statement],
        word('echoerr')               => %w[es_vimCommand Statement],
        word('execute')               => %w[es_vimCommand Statement],
        word('highlight')             => %w[es_vimCommand Statement],
        word('redir')                 => %w[es_vimCommand Statement],
        word('highlight')             => %w[es_vimCommand Statement],
        word('cmap')                  => %w[es_vimCommand Statement],
        word('cmapclear')             => %w[es_vimCommand Statement],
        word('cnoremap')              => %w[es_vimCommand Statement],
        word('cunmap')                => %w[es_vimCommand Statement],
        word('imap')                  => %w[es_vimCommand Statement],
        word('imapclear')             => %w[es_vimCommand Statement],
        word('inoremap')              => %w[es_vimCommand Statement],
        word('iunmap')                => %w[es_vimCommand Statement],
        word('lmap')                  => %w[es_vimCommand Statement],
        word('lmapclear')             => %w[es_vimCommand Statement],
        word('lnoremap')              => %w[es_vimCommand Statement],
        word('lunmap')                => %w[es_vimCommand Statement],
        word('mapclear')              => %w[es_vimCommand Statement],
        word('nmap')                  => %w[es_vimCommand Statement],
        word('nmapclear')             => %w[es_vimCommand Statement],
        word('nnoremap')              => %w[es_vimCommand Statement],
        word('noremap')               => %w[es_vimCommand Statement],
        word('nunmap')                => %w[es_vimCommand Statement],
        word('omap')                  => %w[es_vimCommand Statement],
        word('omapclear')             => %w[es_vimCommand Statement],
        word('onoremap')              => %w[es_vimCommand Statement],
        word('ounmap')                => %w[es_vimCommand Statement],
        word('smap')                  => %w[es_vimCommand Statement],
        word('smapclear')             => %w[es_vimCommand Statement],
        word('snoremap')              => %w[es_vimCommand Statement],
        word('sunmap')                => %w[es_vimCommand Statement],
        word('tmap')                  => %w[es_vimCommand Statement],
        word('tmapclear')             => %w[es_vimCommand Statement],
        word('tnoremap')              => %w[es_vimCommand Statement],
        word('tunmap')                => %w[es_vimCommand Statement],
        word('unmap')                 => %w[es_vimCommand Statement],
        word('vmap')                  => %w[es_vimCommand Statement],
        word('vmapclear')             => %w[es_vimCommand Statement],
        word('vnoremap')              => %w[es_vimCommand Statement],
        word('vunmap')                => %w[es_vimCommand Statement],
        word('xmap')                  => %w[es_vimCommand Statement],
        word('xmapclear')             => %w[es_vimCommand Statement],
        word('xnoremap')              => %w[es_vimCommand Statement],
        word('xunmap')                => %w[es_vimCommand Statement],
        word('abbreviate')            => %w[es_vimCommand Statement],
        word('abclear')               => %w[es_vimCommand Statement],
        word('cabbrev')               => %w[es_vimCommand Statement],
        word('cabclear')              => %w[es_vimCommand Statement],
        word('cnoreabbrev')           => %w[es_vimCommand Statement],
        word('cunabbrev')             => %w[es_vimCommand Statement],
        word('iabbrev')               => %w[es_vimCommand Statement],
        word('iabclear')              => %w[es_vimCommand Statement],
        word('inoreabbrev')           => %w[es_vimCommand Statement],
        word('iunabbrev')             => %w[es_vimCommand Statement],
        word('noreabbrev')            => %w[es_vimCommand Statement],
        word('unabbreviate')          => %w[es_vimCommand Statement],

        word('set')                   => %w[es_vimCommand Statement],
        word('setl')                  => %w[es_vimCommand Statement],
        word('setlocal')              => %w[es_vimCommand Statement],
        word('backspace')             => %w[es_vimOption PreProc],

        region('b:var_Var1')          => %w[es_vimVar Identifier],
        region('w:var_Var2')          => %w[es_vimVar Identifier],
        region('g:var_Var3')          => %w[es_vimVar Identifier],
        region('l:var_Var4')          => %w[es_vimVar Identifier],
        region('s:var_Var5')          => %w[es_vimVar Identifier],
        region('t:var_Var6')          => %w[es_vimVar Identifier],
        region('a:var_Var7')          => %w[es_vimVar Identifier],
        region('v:var_Var8')          => %w[es_vimVar Identifier],

        region('b:var#var')           => %w[es_vimVar Identifier],
        region('w:var#var')           => %w[es_vimVar Identifier],
        region('g:var#var')           => %w[es_vimVar Identifier],
        region('l:var#var')           => %w[es_vimVar Identifier],
        region('s:var#var')           => %w[es_vimVar Identifier],
        region('t:var#var')           => %w[es_vimVar Identifier],
        region('a:var#var')           => %w[es_vimVar Identifier],
        region('v:var#var')           => %w[es_vimVar Identifier],

        word('eval')                  => %w[es_vimFuncName Function],
        word('sha256')                => %w[es_vimFuncName Function],
        word('Function')              => %w[es_vimFunction cleared],
        region('s:name')              => %w[es_vimFunction cleared],
        region('self\.\zsname')       => %w[es_vimFunction cleared],

        region('"string"')            => %w[es_vimString String],
        # that's how vim comments work
        region('"missing quote')      => %w[es_vimComment Comment],
        region('"escaped quote\\\\"') => %w[es_vimString String],
        region("'missing quote")      => %w[es_vimString String],
        region("'escaped quote\\\\'") => %w[es_vimString String],
        region("'string'")            => %w[es_vimString String]
      )
    end
  end
end
