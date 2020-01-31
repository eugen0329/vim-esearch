# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'ruby' do
    let(:ruby_code) do
      <<~RUBY_CODE
        and
        break
        in
        next
        not
        or
        redo
        rescue
        retry
        return
        case
        begin
        do
        for
        if
        unless
        while
        until
        else
        elsif
        ensure
        then
        when
        end

        'string'
        "string"
        "string\\n"
        "str\#{ing}"

        true.call
        false.call

        "unterminated string
        'unterminated string

        alias
        def
        undef
        class Classname
        module Modulename

        Constant
        method

        # comment
        #comment
        # long comment #{'.' * 100}*/

        super
        yield
        include
        extend
        prepend

        nil
        self
        __ENCODING__
        __dir__
        __FILE__
        __LINE__
        __callee__
        __method__
      RUBY_CODE
    end
    let(:source_file) { file(ruby_code, 'main.rb') }
    let!(:test_directory) { directory([source_file], 'window/syntax/').persist! }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: source_file.path.to_s
    end

    it do
      is_expected.to have_highligh_aliases(
        word('and')                    => %w[es_rubyControl Statement],
        word('break')                  => %w[es_rubyControl Statement],
        word('in')                     => %w[es_rubyControl Statement],
        word('next')                   => %w[es_rubyControl Statement],
        word('not')                    => %w[es_rubyControl Statement],
        word('or')                     => %w[es_rubyControl Statement],
        word('redo')                   => %w[es_rubyControl Statement],
        word('rescue')                 => %w[es_rubyControl Statement],
        word('retry')                  => %w[es_rubyControl Statement],
        word('return')                 => %w[es_rubyControl Statement],
        word('case')                   => %w[es_rubyControl Statement],
        word('begin')                  => %w[es_rubyControl Statement],
        word('do')                     => %w[es_rubyControl Statement],
        word('for')                    => %w[es_rubyControl Statement],
        word('if')                     => %w[es_rubyControl Statement],
        word('unless')                 => %w[es_rubyControl Statement],
        word('while')                  => %w[es_rubyControl Statement],
        word('until')                  => %w[es_rubyControl Statement],
        word('else')                   => %w[es_rubyControl Statement],
        word('elsif')                  => %w[es_rubyControl Statement],
        word('ensure')                 => %w[es_rubyControl Statement],
        word('then')                   => %w[es_rubyControl Statement],
        word('when')                   => %w[es_rubyControl Statement],
        word('end')                    => %w[es_rubyControl Statement],

        region('"string"')             => %w[es_rubyString String],
        region('"string\\\\n"')        => %w[es_rubyString String],
        region('"str#{ing}"')          => %w[es_rubyString String], # rubocop:disable Lint/InterpolationCheck
        region("'string'")             => %w[es_rubyString String],

        word('true')                   => %w[es_rubyBoolean Boolean],
        word('false')                  => %w[es_rubyBoolean Boolean],

        region("'unterminated string") => %w[es_rubyString String],
        region('"unterminated string') => %w[es_rubyString String],

        word('alias')                  => %w[es_rubyDefine Define],
        word('def')                    => %w[es_rubyDefine Define],
        word('undef')                  => %w[es_rubyDefine Define],
        word('class')                  => %w[es_rubyDefine Define],
        word('module')                 => %w[es_rubyDefine Define],
        word('Classname')              => %w[es_rubyConstant Type],
        word('Modulename')             => %w[es_rubyConstant Type],

        word('Constant')               => %w[es_rubyConstant Type],
        word('method')                 => %w[win_context_ruby cleared],

        region('# comment')            => %w[es_rubyComment Comment],
        region('#comment')             => %w[es_rubyComment Comment],
        region('# long comment')       => %w[es_rubyComment Comment],

        word('super')                  => %w[es_rubyKeyword Keyword],
        word('yield')                  => %w[es_rubyKeyword Keyword],

        word('include')                => %w[es_rubyMacro Macro],
        word('extend')                 => %w[es_rubyMacro Macro],
        word('prepend')                => %w[es_rubyMacro Macro],

        word('nil')                    => %w[es_rubyPseudoVariable Constant],
        word('self')                   => %w[es_rubyPseudoVariable Constant],
        word('__ENCODING__')           => %w[es_rubyPseudoVariable Constant],
        word('__dir__')                => %w[es_rubyPseudoVariable Constant],
        word('__FILE__')               => %w[es_rubyPseudoVariable Constant],
        word('__LINE__')               => %w[es_rubyPseudoVariable Constant],
        word('__callee__')             => %w[es_rubyPseudoVariable Constant],
        word('__method__')             => %w[es_rubyPseudoVariable Constant]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(ruby_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
