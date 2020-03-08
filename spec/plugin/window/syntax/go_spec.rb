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

        "string"
        "escaped quote\\"
        "str with escape\\n"
        "ellipsized string#{'.' * 500}"
        `raw string`

        defer
        go
        goto
        return
        break
        continue
        fallthrough

        "missing quote
        `unterminated raw string

        case
        default

        // comment line
        /* comment block */
        /* ellipsized comment #{'.' * 500}*/

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
        word('package')                      => %w[es_goDirective Statement],
        word('import')                       => %w[es_goDirective Statement],

        word('var')                          => %w[es_goDeclaration Keyword],
        word('const')                        => %w[es_goDeclaration Keyword],
        word('type')                         => %w[es_goDeclaration Keyword],
        word('func')                         => %w[es_goDeclaration Keyword],
        word('struct')                       => %w[es_goDeclType Keyword],
        word('interface')                    => %w[es_goDeclType Keyword],

        region('"string"')                   => %w[es_goString String],
        region('"missing quote')             => %w[es_goString String],
        region('"escaped quote\\\\"')        => %w[es_goString String],
        region('"str with escape\\\\n"')     => %w[es_goString String],
        region('"ellipsized string[^"]\\+$') => %w[es_goString String],
        region('`raw string`$')              => %w[es_goRawString String],
        region('`missing quote$')            => %w[es_goRawString String],

        word('defer')                        => %w[es_goStatement Statement],
        word('go')                           => %w[es_goStatement Statement],
        word('goto')                         => %w[es_goStatement Statement],
        word('return')                       => %w[es_goStatement Statement],
        word('break')                        => %w[es_goStatement Statement],
        word('continue')                     => %w[es_goStatement Statement],
        word('fallthrough')                  => %w[es_goStatement Statement],

        region('"missing quote')             => %w[es_goString String],
        region('`unterminated raw string')   => %w[es_goRawString String],

        word('case')                         => %w[es_goLabel Label],
        word('default')                      => %w[es_goLabel Label],

        region('// comment line')            => %w[es_goComment Comment],
        region('/\* comment block')          => %w[es_goComment Comment],
        region('/\* ellipsized comment')     => %w[es_goComment Comment],

        word('for')                          => %w[es_goRepeat Repeat],
        word('range')                        => %w[es_goRepeat Repeat]
      )
    end
  end
end
