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

        "unterminated string
        'unterminated string

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
      esearch.configure!(regex: 1, backend: 'system', adapter: 'ag', out: 'win')
      esearch.search! '^', cwd: main_rb.path.to_s
      expect(esearch).to have_search_finished
    end

    it do
      is_expected.to have_highligh_aliases(
        word('False')                  => %w[es_pythonStatement Statement],
        word('None')                   => %w[es_pythonStatement Statement],
        word('True')                   => %w[es_pythonStatement Statement],
        word('as')                     => %w[es_pythonStatement Statement],
        word('assert')                 => %w[es_pythonStatement Statement],
        word('break')                  => %w[es_pythonStatement Statement],
        word('continue')               => %w[es_pythonStatement Statement],
        word('del')                    => %w[es_pythonStatement Statement],
        word('exec')                   => %w[es_pythonStatement Statement],
        word('global')                 => %w[es_pythonStatement Statement],
        word('lambda')                 => %w[es_pythonStatement Statement],
        word('nonlocal')               => %w[es_pythonStatement Statement],
        word('pass')                   => %w[es_pythonStatement Statement],
        word('print')                  => %w[es_pythonStatement Statement],
        word('return')                 => %w[es_pythonStatement Statement],
        word('with')                   => %w[es_pythonStatement Statement],
        word('yield')                  => %w[es_pythonStatement Statement],

        word('class')                  => %w[es_pythonStatement Statement],
        word('def')                    => %w[es_pythonStatement Statement],
        word('Classname')              => %w[es_pythonFunction Function],
        word('function')               => %w[es_pythonFunction Function],

        word('elif')                   => %w[es_pythonConditional Conditional],
        word('else')                   => %w[es_pythonConditional Conditional],
        word('if')                     => %w[es_pythonConditional Conditional],

        region('"string"')             => %w[es_pythonString String],
        region('"string\\\\n"')        => %w[es_pythonString String],
        region("'string'")             => %w[es_pythonString String],
        region("'string\\\\n'")        => %w[es_pythonString String],
        region('"""string"""')         => %w[es_pythonString String],
        region('"""string\\\\n"""')    => %w[es_pythonString String],
        region("'''string'''")         => %w[es_pythonString String],
        region("'''string\\\\n'''")    => %w[es_pythonString String],

        region('r"string"')            => %w[es_pythonString String],
        region('r"string\\\\n"')       => %w[es_pythonString String],
        region("r'string'")            => %w[es_pythonString String],
        region("r'string\\\\n'")       => %w[es_pythonString String],
        region('r"""string"""')        => %w[es_pythonString String],
        region('r"""string\\\\n"""')   => %w[es_pythonString String],
        region("r'''string'''")        => %w[es_pythonString String],
        region("r'''string\\\\n'''")   => %w[es_pythonString String],
        region('R"string"')            => %w[es_pythonString String],
        region('R"string\\\\n"')       => %w[es_pythonString String],
        region("R'string'")            => %w[es_pythonString String],
        region("R'string\\\\n'")       => %w[es_pythonString String],
        region('R"""string"""')        => %w[es_pythonString String],
        region('R"""string\\\\n"""')   => %w[es_pythonString String],
        region("R'''string'''")        => %w[es_pythonString String],
        region("R'''string\\\\n'''")   => %w[es_pythonString String],

        word('for')                    => %w[es_pythonRepeat Repeat],
        word('while')                  => %w[es_pythonRepeat Repeat],

        region('# comment')            => %w[es_pythonComment Comment],
        region('#comment')             => %w[es_pythonComment Comment],
        region('# long comment')       => %w[es_pythonComment Comment],

        word('and')                    => %w[es_pythonOperator Operator],
        word('in')                     => %w[es_pythonOperator Operator],
        word('is')                     => %w[es_pythonOperator Operator],
        word('not')                    => %w[es_pythonOperator Operator],
        word('or')                     => %w[es_pythonOperator Operator],

        region("'unterminated string") => %w[es_pythonString String],
        region('"unterminated string') => %w[es_pythonString String],

        word('except')                 => %w[es_pythonException Exception],
        word('finally')                => %w[es_pythonException Exception],
        word('raise')                  => %w[es_pythonException Exception],
        word('try')                    => %w[es_pythonException Exception],

        word('from')                   => %w[es_pythonInclude Include],
        word('import')                 => %w[es_pythonInclude Include],

        word('async')                  => %w[es_pythonAsync Statement],
        word('await')                  => %w[es_pythonAsync Statement]
      )
    end

    it 'keeps lines highligh untouched' do
      expect(python_code).to have_line_numbers_highlight(%w[esearchLnum LineNr])
    end
  end
end
