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

        # comment
        #comment
        # long comment #{'.' * 100}*/

        alias
        def
        undef
        class
        module

        super.call
        yield.call

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
    let(:main_rb) { file(ruby_code, 'main.rb') }
    let!(:test_directory) { directory([main_rb], 'window/syntax/').persist! }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: main_rb.path.to_s
    end

    it 'contains matches' do
      is_expected.to have_highligh_aliases(
        word('and')              => %w[rubyControl Statement],
        word('break')            => %w[rubyControl Statement],
        word('in')               => %w[rubyControl Statement],
        word('next')             => %w[rubyControl Statement],
        word('not')              => %w[rubyControl Statement],
        word('or')               => %w[rubyControl Statement],
        word('redo')             => %w[rubyControl Statement],
        word('rescue')           => %w[rubyControl Statement],
        word('retry')            => %w[rubyControl Statement],
        word('return')           => %w[rubyControl Statement],
        word('case')             => %w[rubyControl Statement],
        word('begin')            => %w[rubyControl Statement],
        word('do')               => %w[rubyControl Statement],
        word('for')              => %w[rubyControl Statement],
        word('if')               => %w[rubyControl Statement],
        word('unless')           => %w[rubyControl Statement],
        word('while')            => %w[rubyControl Statement],
        word('until')            => %w[rubyControl Statement],
        word('else')             => %w[rubyControl Statement],
        word('elsif')            => %w[rubyControl Statement],
        word('ensure')           => %w[rubyControl Statement],
        word('then')             => %w[rubyControl Statement],
        word('when')             => %w[rubyControl Statement],
        word('end')              => %w[rubyControl Statement],

        region('"string"')       => %w[rubyString String],
        region('"string\\\\n"')  => %w[rubyString String],
        region('"str#{ing}"')    => %w[rubyString String], # rubocop:disable Lint/InterpolationCheck
        region("'string'")       => %w[rubyString String],

        word('true')             => %w[rubyBoolean Boolean],
        word('false')            => %w[rubyBoolean Boolean],

        region('# comment')      => %w[rubyComment Comment],
        region('#comment')       => %w[rubyComment Comment],
        region('# long comment') => %w[rubyComment Comment],

        word('alias')            => %w[rubyDefine Define],
        word('def')              => %w[rubyDefine Define],
        word('undef')            => %w[rubyDefine Define],
        word('class')            => %w[rubyDefine Define],
        word('module')           => %w[rubyDefine Define],

        word('super')            => %w[rubyKeyword Keyword],
        word('yield')            => %w[rubyKeyword Keyword],

        word('nil')              => %w[rubyPseudoVariable Constant],
        word('self')             => %w[rubyPseudoVariable Constant],
        word('__ENCODING__')     => %w[rubyPseudoVariable Constant],
        word('__dir__')          => %w[rubyPseudoVariable Constant],
        word('__FILE__')         => %w[rubyPseudoVariable Constant],
        word('__LINE__')         => %w[rubyPseudoVariable Constant],
        word('__callee__')       => %w[rubyPseudoVariable Constant],
        word('__method__')       => %w[rubyPseudoVariable Constant]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(ruby_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
