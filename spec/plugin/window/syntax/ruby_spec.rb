# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::Syntax

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
      is_expected.to have_highlights(
        'and':            %w[rubyControl Statement],
        'break':          %w[rubyControl Statement],
        'in':             %w[rubyControl Statement],
        'next':           %w[rubyControl Statement],
        'not':            %w[rubyControl Statement],
        'or':             %w[rubyControl Statement],
        'redo':           %w[rubyControl Statement],
        'rescue':         %w[rubyControl Statement],
        'retry':          %w[rubyControl Statement],
        'return':         %w[rubyControl Statement],
        'case':           %w[rubyControl Statement],
        'begin':          %w[rubyControl Statement],
        'do':             %w[rubyControl Statement],
        'for':            %w[rubyControl Statement],
        'if':             %w[rubyControl Statement],
        'unless':         %w[rubyControl Statement],
        'while':          %w[rubyControl Statement],
        'until':          %w[rubyControl Statement],
        'else':           %w[rubyControl Statement],
        'elsif':          %w[rubyControl Statement],
        'ensure':         %w[rubyControl Statement],
        'then':           %w[rubyControl Statement],
        'when':           %w[rubyControl Statement],
        'end':            %w[rubyControl Statement],

        '"string"':       %w[rubyString String],
        '"string\\\\n"':  %w[rubyString String],
        '"str#{ing}"':    %w[rubyString String],
        "'string'":       %w[rubyString String],

        'true':           %w[rubyBoolean Boolean],
        'false':          %w[rubyBoolean Boolean],

        '# comment':      %w[rubyComment Comment],
        '#comment':       %w[rubyComment Comment],
        '# long comment': %w[rubyComment Comment],

        'alias':          %w[rubyDefine Define],
        'def':            %w[rubyDefine Define],
        'undef':          %w[rubyDefine Define],
        'class':          %w[rubyDefine Define],
        'module':         %w[rubyDefine Define],

        'super':          %w[rubyKeyword Keyword],
        'yield':          %w[rubyKeyword Keyword],

        'nil':            %w[rubyPseudoVariable Constant],
        'self':           %w[rubyPseudoVariable Constant],
        '__ENCODING__':   %w[rubyPseudoVariable Constant],
        '__dir__':        %w[rubyPseudoVariable Constant],
        '__FILE__':       %w[rubyPseudoVariable Constant],
        '__LINE__':       %w[rubyPseudoVariable Constant],
        '__callee__':     %w[rubyPseudoVariable Constant],
        '__method__':     %w[rubyPseudoVariable Constant]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(ruby_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
