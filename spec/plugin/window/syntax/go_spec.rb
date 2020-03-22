# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'go' do
    let(:source_file_content) do
      <<~SOURCE
        package main
        import "fmt"
        var a int
        const b int
        func main() {}
        type _ struct {}
        type _ interface {}
        "es_goString"
        "escaped quote\\"
        "str with escape\\n"
        `es_goRawString`
        defer
        go
        goto
        return
        break
        continue
        fallthrough
        "unterminated es_goString
        `unterminated es_goRawString
        case
        default

        append
        cap
        close
        complex
        copy
        delete
        imag
        len
        make
        new
        panic
        print
        println
        real
        recover
        iota
        true
        false
        nil
        chan
        map
        bool
        string
        error
        int
        int8
        int16
        int32
        int64
        rune
        byte
        uint
        uint8
        uint16
        uint32
        uint64
        uintptr
        float32
        float64
        complex64
        complex128

        // comment line
        /* comment block */
        /* ellipsized comment #{'.' * 300}*/
        for {}
        range()
      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.go') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('package')                        => %w[es_goDirective Statement],
        word('import')                         => %w[es_goDirective Statement],

        word('var')                            => %w[es_goDeclaration Keyword],
        word('const')                          => %w[es_goDeclaration Keyword],
        word('type')                           => %w[es_goDeclaration Keyword],
        word('func')                           => %w[es_goDeclaration Keyword],
        word('struct')                         => %w[es_goDeclType Keyword],
        word('interface')                      => %w[es_goDeclType Keyword],

        region('"es_goString"')                => %w[es_goString String],
        region('"escaped quote\\\\"')          => %w[es_goString String],
        region('"str with escape\\\\n"')       => %w[es_goString String],
        region('`es_goRawString`$')            => %w[es_goRawString String],

        word('defer')                          => %w[es_goStatement Statement],
        word('go')                             => %w[es_goStatement Statement],
        word('goto')                           => %w[es_goStatement Statement],
        word('return')                         => %w[es_goStatement Statement],
        word('break')                          => %w[es_goStatement Statement],
        word('continue')                       => %w[es_goStatement Statement],
        word('fallthrough')                    => %w[es_goStatement Statement],

        region('"unterminated es_goString')    => %w[es_goString String],
        region('`unterminated es_goRawString') => %w[es_goRawString String],

        word('case')                           => %w[es_goLabel Label],
        word('default')                        => %w[es_goLabel Label],

        region('// comment line')              => %w[es_goComment Comment],
        region('/\* comment block')            => %w[es_goComment Comment],
        region('/\* ellipsized comment')       => %w[es_goComment Comment],

        word('for')                            => %w[es_goRepeat Repeat],
        word('range')                          => %w[es_goRepeat Repeat],

        word('append')                         => %w[es_goBuiltins Keyword],
        word('cap')                            => %w[es_goBuiltins Keyword],
        word('close')                          => %w[es_goBuiltins Keyword],
        word('complex')                        => %w[es_goBuiltins Keyword],
        word('copy')                           => %w[es_goBuiltins Keyword],
        word('delete')                         => %w[es_goBuiltins Keyword],
        word('imag')                           => %w[es_goBuiltins Keyword],
        word('len')                            => %w[es_goBuiltins Keyword],
        word('make')                           => %w[es_goBuiltins Keyword],
        word('new')                            => %w[es_goBuiltins Keyword],
        word('panic')                          => %w[es_goBuiltins Keyword],
        word('print')                          => %w[es_goBuiltins Keyword],
        word('println')                        => %w[es_goBuiltins Keyword],
        word('real')                           => %w[es_goBuiltins Keyword],
        word('recover')                        => %w[es_goBuiltins Keyword],
        word('iota')                           => %w[es_goConstants Keyword],
        word('true')                           => %w[es_goConstants Keyword],
        word('false')                          => %w[es_goConstants Keyword],
        word('nil')                            => %w[es_goConstants Keyword],
        word('chan')                           => %w[es_goType Type],
        word('map')                            => %w[es_goType Type],
        word('bool')                           => %w[es_goType Type],
        word('string')                         => %w[es_goType Type],
        word('error')                          => %w[es_goType Type],
        word('int')                            => %w[es_goType Type],
        word('int8')                           => %w[es_goType Type],
        word('int16')                          => %w[es_goType Type],
        word('int32')                          => %w[es_goType Type],
        word('int64')                          => %w[es_goType Type],
        word('rune')                           => %w[es_goType Type],
        word('byte')                           => %w[es_goType Type],
        word('uint')                           => %w[es_goType Type],
        word('uint8')                          => %w[es_goType Type],
        word('uint16')                         => %w[es_goType Type],
        word('uint32')                         => %w[es_goType Type],
        word('uint64')                         => %w[es_goType Type],
        word('uintptr')                        => %w[es_goType Type],
        word('float32')                        => %w[es_goType Type],
        word('float64')                        => %w[es_goType Type],
        word('complex64')                      => %w[es_goType Type],
        word('complex128')                     => %w[es_goType Type]
      )
    end
  end
end
