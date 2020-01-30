# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::Syntax

  describe 'python' do
    let(:python_code) do
      <<~PYTHON_CODE
        False
        None
        True
        as
        assert
        break
        continue
        del
        exec
        global
        lambda
        nonlocal
        pass
        print
        return
        with
        yield
        class Classname
        def function

        elif
        else
        if


        "string"
        "string\\n"
        'string'
        'string\\n'
        '''string'''
        '''string\\n'''
        """string"""
        """string\\n"""

        r"string"
        r"string\\n"
        r'string'
        r'string\\n'
        r'''string'''
        r'''string\\n'''
        r"""string"""
        r"""string\\n"""

        R"string"
        R"string\\n"
        R'string'
        R'string\\n'
        R'''string'''
        R'''string\\n'''
        R"""string"""
        R"""string\\n"""

        for
        while

        # comment
        #comment
        # long comment #{'.' * 100}*/

        and
        in
        is
        not
        or

        except
        finally
        raise
        try

        from
        import

        async
        await
      PYTHON_CODE
    end
    let(:main_rb) { file(python_code, 'main.py') }
    let!(:test_directory) { directory([main_rb], 'window/syntax/').persist! }

    before do
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag')
      esearch.search! '^', cwd: main_rb.path.to_s
    end

    it 'contains matches' do
      is_expected.to have_highlights(
        'False':              %w[pythonStatement Statement],
        'None':               %w[pythonStatement Statement],
        'True':               %w[pythonStatement Statement],
        'as':                 %w[pythonStatement Statement],
        'assert':             %w[pythonStatement Statement],
        'break':              %w[pythonStatement Statement],
        'continue':           %w[pythonStatement Statement],
        'del':                %w[pythonStatement Statement],
        'exec':               %w[pythonStatement Statement],
        'global':             %w[pythonStatement Statement],
        'lambda':             %w[pythonStatement Statement],
        'nonlocal':           %w[pythonStatement Statement],
        'pass':               %w[pythonStatement Statement],
        'print':              %w[pythonStatement Statement],
        'return':             %w[pythonStatement Statement],
        'with':               %w[pythonStatement Statement],
        'yield':              %w[pythonStatement Statement],

        'class':              %w[pythonStatement Statement],
        'def':                %w[pythonStatement Statement],
        'Classname':          %w[pythonFunction Function],
        'function':           %w[pythonFunction Function],

        'elif':               %w[pythonConditional Conditional],
        'else':               %w[pythonConditional Conditional],
        'if':                 %w[pythonConditional Conditional],

        '"string"':           %w[pythonString String],
        '"string\\\\n"':      %w[pythonString String],
        "'string'":           %w[pythonString String],
        "'string\\\\n'":      %w[pythonString String],
        '"""string"""':       %w[pythonString String],
        '"""string\\\\n"""':  %w[pythonString String],
        "'''string'''":       %w[pythonString String],
        "'''string\\\\n'''":  %w[pythonString String],

        'r"string"':          %w[pythonString String],
        'r"string\\\\n"':     %w[pythonString String],
        "r'string'":          %w[pythonString String],
        "r'string\\\\n'":     %w[pythonString String],
        'r"""string"""':      %w[pythonString String],
        'r"""string\\\\n"""': %w[pythonString String],
        "r'''string'''":      %w[pythonString String],
        "r'''string\\\\n'''": %w[pythonString String],
        'R"string"':          %w[pythonString String],
        'R"string\\\\n"':     %w[pythonString String],
        "R'string'":          %w[pythonString String],
        "R'string\\\\n'":     %w[pythonString String],
        'R"""string"""':      %w[pythonString String],
        'R"""string\\\\n"""': %w[pythonString String],
        "R'''string'''":      %w[pythonString String],
        "R'''string\\\\n'''": %w[pythonString String],

        'for':                %w[pythonRepeat Repeat],
        'while':              %w[pythonRepeat Repeat],

        '# comment':          %w[pythonComment Comment],
        '#comment':           %w[pythonComment Comment],
        '# long comment':     %w[pythonComment Comment],

        'and':                %w[pythonOperator Operator],
        'in':                 %w[pythonOperator Operator],
        'is':                 %w[pythonOperator Operator],
        'not':                %w[pythonOperator Operator],
        'or':                 %w[pythonOperator Operator],

        'except':             %w[pythonException Exception],
        'finally':            %w[pythonException Exception],
        'raise':              %w[pythonException Exception],
        'try':                %w[pythonException Exception],

        'from':               %w[pythonInclude Include],
        'import':             %w[pythonInclude Include],

        'async':              %w[pythonAsync Statement],
        'await':              %w[pythonAsync Statement]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(python_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
