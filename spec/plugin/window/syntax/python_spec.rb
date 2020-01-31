# frozen_string_literal: true

require 'spec_helper'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

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
      is_expected.to have_highligh_aliases(
        word('False')                => %w[pythonStatement Statement],
        word('None')                 => %w[pythonStatement Statement],
        word('True')                 => %w[pythonStatement Statement],
        word('as')                   => %w[pythonStatement Statement],
        word('assert')               => %w[pythonStatement Statement],
        word('break')                => %w[pythonStatement Statement],
        word('continue')             => %w[pythonStatement Statement],
        word('del')                  => %w[pythonStatement Statement],
        word('exec')                 => %w[pythonStatement Statement],
        word('global')               => %w[pythonStatement Statement],
        word('lambda')               => %w[pythonStatement Statement],
        word('nonlocal')             => %w[pythonStatement Statement],
        word('pass')                 => %w[pythonStatement Statement],
        word('print')                => %w[pythonStatement Statement],
        word('return')               => %w[pythonStatement Statement],
        word('with')                 => %w[pythonStatement Statement],
        word('yield')                => %w[pythonStatement Statement],

        word('class')                => %w[pythonStatement Statement],
        word('def')                  => %w[pythonStatement Statement],
        word('Classname')            => %w[pythonFunction Function],
        word('function')             => %w[pythonFunction Function],

        word('elif')                 => %w[pythonConditional Conditional],
        word('else')                 => %w[pythonConditional Conditional],
        word('if')                   => %w[pythonConditional Conditional],

        region('"string"')           => %w[pythonString String],
        region('"string\\\\n"')      => %w[pythonString String],
        region("'string'")           => %w[pythonString String],
        region("'string\\\\n'")      => %w[pythonString String],
        region('"""string"""')       => %w[pythonString String],
        region('"""string\\\\n"""')  => %w[pythonString String],
        region("'''string'''")       => %w[pythonString String],
        region("'''string\\\\n'''")  => %w[pythonString String],

        region('r"string"')          => %w[pythonString String],
        region('r"string\\\\n"')     => %w[pythonString String],
        region("r'string'")          => %w[pythonString String],
        region("r'string\\\\n'")     => %w[pythonString String],
        region('r"""string"""')      => %w[pythonString String],
        region('r"""string\\\\n"""') => %w[pythonString String],
        region("r'''string'''")      => %w[pythonString String],
        region("r'''string\\\\n'''") => %w[pythonString String],
        region('R"string"')          => %w[pythonString String],
        region('R"string\\\\n"')     => %w[pythonString String],
        region("R'string'")          => %w[pythonString String],
        region("R'string\\\\n'")     => %w[pythonString String],
        region('R"""string"""')      => %w[pythonString String],
        region('R"""string\\\\n"""') => %w[pythonString String],
        region("R'''string'''")      => %w[pythonString String],
        region("R'''string\\\\n'''") => %w[pythonString String],

        word('for')                  => %w[pythonRepeat Repeat],
        word('while')                => %w[pythonRepeat Repeat],

        region('# comment')          => %w[pythonComment Comment],
        region('#comment')           => %w[pythonComment Comment],
        region('# long comment')     => %w[pythonComment Comment],

        word('and')                  => %w[pythonOperator Operator],
        word('in')                   => %w[pythonOperator Operator],
        word('is')                   => %w[pythonOperator Operator],
        word('not')                  => %w[pythonOperator Operator],
        word('or')                   => %w[pythonOperator Operator],

        word('except')               => %w[pythonException Exception],
        word('finally')              => %w[pythonException Exception],
        word('raise')                => %w[pythonException Exception],
        word('try')                  => %w[pythonException Exception],

        word('from')                 => %w[pythonInclude Include],
        word('import')               => %w[pythonInclude Include],

        word('async')                => %w[pythonAsync Statement],
        word('await')                => %w[pythonAsync Statement]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(python_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
