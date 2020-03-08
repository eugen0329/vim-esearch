# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'json' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
        abbr {}
        address {}
        area {}
        a {}
        b {}
        base {}
        bdo {}
        blockquote {}
        body {}
        br {}
        button {}
        caption {}
        cite {}
        code {}
        col {}
        colgroup {}
        dd {}
        del {}
        dfn {}
        div {}
        dl {}
        dt {}
        em {}
        fieldset {}
        form {}
        h1 {}
        h2 {}
        h3 {}
        h4 {}
        h5 {}
        h6 {}
        head {}
        hr {}
        html {}
        img {}
        i {}
        iframe {}
        input {}
        ins {}
        isindex {}
        kbd {}
        label {}
        legend {}
        li {}
        link {}
        map {}
        menu {}
        meta {}
        noscript {}
        ol {}
        optgroup {}
        option {}
        p {}
        param {}
        pre {}
        q {}
        s {}
        samp {}
        script {}
        small {}
        span {}
        strong {}
        sub {}
        sup {}
        tbody {}
        td {}
        textarea {}
        tfoot {}
        th {}
        thead {}
        title {}
        tr {}
        ul {}
        u {}
        var {}
        object {}
        svg {}
        article {}
        aside {}
        audio {}
        bdi {}
        canvas {}
        command {}
        data {}
        datalist {}
        details {}
        dialog {}
        embed {}
        figcaption {}
        figure {}
        footer {}
        header {}
        hgroup {}
        keygen {}
        main {}
        mark {}
        menuitem {}
        meter {}
        nav {}
        output {}
        progress {}
        rt {}
        rp {}
        ruby {}
        section {}
        source {}
        summary {}
        time {}
        track {}
        video {}
        wbr {}
        * {}
        select {}
        style {}
        table {}

        a[es_cssAttributeSelector] {
          color: red;
          -color: red;
          --co-lor: red;
        }
        'es_cssString'
        'es_cssString\\'
        'es_cssString
        "es_cssString"
        "es_cssString\\"
        "es_cssString

        .class {}
        .c_lass {}
        .c-lass {}
        #identifier {}
        #iden_tifier {}
        #iden-tifier {}

        $sassvar
        $-sassvar
        $--v-a_riable

        @function
        @include
        @extend
        @mixin
        @charset
        @import
        @return

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.css') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('abbr')                    => %w[es_cssTagName Statement],
        word('address')                 => %w[es_cssTagName Statement],
        word('area')                    => %w[es_cssTagName Statement],
        word('a')                       => %w[es_cssTagName Statement],
        word('b')                       => %w[es_cssTagName Statement],
        word('base')                    => %w[es_cssTagName Statement],
        word('bdo')                     => %w[es_cssTagName Statement],
        word('blockquote')              => %w[es_cssTagName Statement],
        word('body')                    => %w[es_cssTagName Statement],
        word('br')                      => %w[es_cssTagName Statement],
        word('button')                  => %w[es_cssTagName Statement],
        word('caption')                 => %w[es_cssTagName Statement],
        word('cite')                    => %w[es_cssTagName Statement],
        word('code')                    => %w[es_cssTagName Statement],
        word('col')                     => %w[es_cssTagName Statement],
        word('colgroup')                => %w[es_cssTagName Statement],
        word('dd')                      => %w[es_cssTagName Statement],
        word('del')                     => %w[es_cssTagName Statement],
        word('dfn')                     => %w[es_cssTagName Statement],
        word('div')                     => %w[es_cssTagName Statement],
        word('dl')                      => %w[es_cssTagName Statement],
        word('dt')                      => %w[es_cssTagName Statement],
        word('em')                      => %w[es_cssTagName Statement],
        word('fieldset')                => %w[es_cssTagName Statement],
        word('form')                    => %w[es_cssTagName Statement],
        word('h1')                      => %w[es_cssTagName Statement],
        word('h2')                      => %w[es_cssTagName Statement],
        word('h3')                      => %w[es_cssTagName Statement],
        word('h4')                      => %w[es_cssTagName Statement],
        word('h5')                      => %w[es_cssTagName Statement],
        word('h6')                      => %w[es_cssTagName Statement],
        word('head')                    => %w[es_cssTagName Statement],
        word('hr')                      => %w[es_cssTagName Statement],
        word('html')                    => %w[es_cssTagName Statement],
        word('img')                     => %w[es_cssTagName Statement],
        word('i')                       => %w[es_cssTagName Statement],
        word('iframe')                  => %w[es_cssTagName Statement],
        word('input')                   => %w[es_cssTagName Statement],
        word('ins')                     => %w[es_cssTagName Statement],
        word('isindex')                 => %w[es_cssTagName Statement],
        word('kbd')                     => %w[es_cssTagName Statement],
        word('label')                   => %w[es_cssTagName Statement],
        word('legend')                  => %w[es_cssTagName Statement],
        word('li')                      => %w[es_cssTagName Statement],
        word('link')                    => %w[es_cssTagName Statement],
        word('map')                     => %w[es_cssTagName Statement],
        word('menu')                    => %w[es_cssTagName Statement],
        word('meta')                    => %w[es_cssTagName Statement],
        word('noscript')                => %w[es_cssTagName Statement],
        word('ol')                      => %w[es_cssTagName Statement],
        word('optgroup')                => %w[es_cssTagName Statement],
        word('option')                  => %w[es_cssTagName Statement],
        word('p')                       => %w[es_cssTagName Statement],
        word('param')                   => %w[es_cssTagName Statement],
        word('pre')                     => %w[es_cssTagName Statement],
        word('q')                       => %w[es_cssTagName Statement],
        word('s')                       => %w[es_cssTagName Statement],
        word('samp')                    => %w[es_cssTagName Statement],
        word('script')                  => %w[es_cssTagName Statement],
        word('small')                   => %w[es_cssTagName Statement],
        word('span')                    => %w[es_cssTagName Statement],
        word('strong')                  => %w[es_cssTagName Statement],
        word('sub')                     => %w[es_cssTagName Statement],
        word('sup')                     => %w[es_cssTagName Statement],
        word('tbody')                   => %w[es_cssTagName Statement],
        word('td')                      => %w[es_cssTagName Statement],
        word('textarea')                => %w[es_cssTagName Statement],
        word('tfoot')                   => %w[es_cssTagName Statement],
        word('th')                      => %w[es_cssTagName Statement],
        word('thead')                   => %w[es_cssTagName Statement],
        word('title')                   => %w[es_cssTagName Statement],
        word('tr')                      => %w[es_cssTagName Statement],
        word('ul')                      => %w[es_cssTagName Statement],
        word('u')                       => %w[es_cssTagName Statement],
        word('var')                     => %w[es_cssTagName Statement],
        word('object')                  => %w[es_cssTagName Statement],
        word('svg')                     => %w[es_cssTagName Statement],
        word('article')                 => %w[es_cssTagName Statement],
        word('aside')                   => %w[es_cssTagName Statement],
        word('audio')                   => %w[es_cssTagName Statement],
        word('bdi')                     => %w[es_cssTagName Statement],
        word('canvas')                  => %w[es_cssTagName Statement],
        word('command')                 => %w[es_cssTagName Statement],
        word('data')                    => %w[es_cssTagName Statement],
        word('datalist')                => %w[es_cssTagName Statement],
        word('details')                 => %w[es_cssTagName Statement],
        word('dialog')                  => %w[es_cssTagName Statement],
        word('embed')                   => %w[es_cssTagName Statement],
        word('figcaption')              => %w[es_cssTagName Statement],
        word('figure')                  => %w[es_cssTagName Statement],
        word('footer')                  => %w[es_cssTagName Statement],
        word('header')                  => %w[es_cssTagName Statement],
        word('hgroup')                  => %w[es_cssTagName Statement],
        word('keygen')                  => %w[es_cssTagName Statement],
        word('main')                    => %w[es_cssTagName Statement],
        word('mark')                    => %w[es_cssTagName Statement],
        word('menuitem')                => %w[es_cssTagName Statement],
        word('meter')                   => %w[es_cssTagName Statement],
        word('nav')                     => %w[es_cssTagName Statement],
        word('output')                  => %w[es_cssTagName Statement],
        word('progress')                => %w[es_cssTagName Statement],
        word('rt')                      => %w[es_cssTagName Statement],
        word('rp')                      => %w[es_cssTagName Statement],
        word('ruby')                    => %w[es_cssTagName Statement],
        word('section')                 => %w[es_cssTagName Statement],
        word('source')                  => %w[es_cssTagName Statement],
        word('summary')                 => %w[es_cssTagName Statement],
        word('time')                    => %w[es_cssTagName Statement],
        word('track')                   => %w[es_cssTagName Statement],
        word('video')                   => %w[es_cssTagName Statement],
        word('wbr')                     => %w[es_cssTagName Statement],
        char('*')                       => %w[es_cssTagName Statement],
        word('select')                  => %w[es_cssTagName Statement],
        word('style')                   => %w[es_cssTagName Statement],
        word('table')                   => %w[es_cssTagName Statement],
        word('es_cssAttributeSelector') => %w[es_cssAttributeSelector String],

        region('color')                 => %w[es_cssProp StorageClass],
        region('-color')                => %w[es_cssProp StorageClass],
        region('--co-lor')              => %w[es_cssProp StorageClass],

        region("'es_cssString'")        => %w[es_cssString String],
        region("'es_cssString\\'")      => %w[es_cssString String],
        region("'es_cssString")         => %w[es_cssString String],
        region('"es_cssString"')        => %w[es_cssString String],
        region('"es_cssString\\"')      => %w[es_cssString String],
        region('"es_cssString')         => %w[es_cssString String],

        region('\.class')               => %w[es_cssClassOrId Function],
        region('\.c_lass')              => %w[es_cssClassOrId Function],
        region('\.c-lass')              => %w[es_cssClassOrId Function],
        region('#identifier')           => %w[es_cssClassOrId Function],
        region('#iden_tifier')          => %w[es_cssClassOrId Function],
        region('#iden-tifier')          => %w[es_cssClassOrId Function],

        region('[$]sassvar')            => %w[es_sassVariable Identifier],
        region('[$]-sassvar')           => %w[es_sassVariable Identifier],
        region('[$]--v-a_riable')       => %w[es_sassVariable Identifier],

        region('@function')             => %w[es_sassPreProc PreProc],
        region('@include')              => %w[es_sassPreProc PreProc],
        region('@extend')               => %w[es_sassPreProc PreProc],
        region('@mixin')                => %w[es_sassPreProc PreProc],
        region('@charset')              => %w[es_sassPreProc PreProc],
        region('@import')               => %w[es_sassPreProc PreProc],
        region('@return')               => %w[es_sassPreProc PreProc]
      )
    end
  end
end
