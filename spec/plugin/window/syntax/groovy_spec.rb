# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'groovy' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
        native
        package
        goto
        const
        if
        else
        switch
        while
        for
        do
        true
        false
        null
        this
        super
        new
        instanceof
        return
        throw
        try
        catch
        finally
        as
        def
        in
        div
        minus
        plus
        abs
        round
        power
        multiply
        each
        call
        inject
        sort
        print
        println
        getAt
        putAt
        size
        push
        pop
        toList
        getText
        writeLine
        eachLine
        readLines
        withReader
        withStream
        withWriter
        withPrintWriter
        write
        read
        leftShift
        withWriterAppend
        readBytes
        splitEachLine
        newInputStream
        newOutputStream
        newPrintWriter
        newReader
        newWriter
        compareTo
        next
        previous
        isCase
        times
        step
        toInteger
        upto
        any
        collect
        dump
        every
        find
        findAll
        grep
        inspect
        invokeMethods
        join
        getErr
        getIn
        getOut
        waitForOrKill
        count
        tokenize
        asList
        flatten
        immutable
        intersect
        reverse
        reverseEach
        subMap
        append
        asWritable
        eachByte
        eachLine
        eachFile
          .class
        import static
        checkout
        docker
        node
        scm
        sh
        stage
        parallel
        steps
        step
        tool
        post
        always
        changed
        failure
        success
        unstable
        aborted
        'es_groovyString'
        'es_groovyString
        'es_groovyString\\'
        '''es_groovyString'''
        '''es_groovyString
        "es_groovyString"
        "es_groovyString
        "es_groovyString\\"
        """es_groovyString"""
        """es_groovyString
        /*es_groovyComment*/
        /* es_groovyComment */
        /*es_groovyComment
        /* es_groovyComment
        /**/
      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.groovy') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('import static')                => %w[es_groovyExternal Include],
        word('native')                       => %w[es_groovyExternal Include],
        word('package')                      => %w[es_groovyExternal Include],
        word('goto')                         => %w[es_groovyError Error],
        word('const')                        => %w[es_groovyError Error],
        word('if')                           => %w[es_groovyConditional Conditional],
        word('else')                         => %w[es_groovyConditional Conditional],
        word('switch')                       => %w[es_groovyConditional Conditional],
        word('while')                        => %w[es_groovyRepeat Repeat],
        word('for')                          => %w[es_groovyRepeat Repeat],
        word('do')                           => %w[es_groovyRepeat Repeat],
        word('true')                         => %w[es_groovyBoolean Boolean],
        word('false')                        => %w[es_groovyBoolean Boolean],
        word('null')                         => %w[es_groovyConstant Constant],
        word('this')                         => %w[es_groovyTypedef Typedef],
        word('super')                        => %w[es_groovyTypedef Typedef],
        word('class')                        => %w[es_groovyTypedef Typedef],
        word('new')                          => %w[es_groovyOperator Operator],
        word('instanceof')                   => %w[es_groovyOperator Operator],
        word('return')                       => %w[es_groovyStatement Statement],
        word('throw')                        => %w[es_groovyExceptions Exception],
        word('try')                          => %w[es_groovyExceptions Exception],
        word('catch')                        => %w[es_groovyExceptions Exception],
        word('finally')                      => %w[es_groovyExceptions Exception],
        word('as')                           => %w[es_groovyJDKBuiltin Special],
        word('def')                          => %w[es_groovyJDKBuiltin Special],
        word('in')                           => %w[es_groovyJDKBuiltin Special],
        word('div')                          => %w[es_groovyJDKOperOverl Operator],
        word('minus')                        => %w[es_groovyJDKOperOverl Operator],
        word('plus')                         => %w[es_groovyJDKOperOverl Operator],
        word('abs')                          => %w[es_groovyJDKOperOverl Operator],
        word('round')                        => %w[es_groovyJDKOperOverl Operator],
        word('power')                        => %w[es_groovyJDKOperOverl Operator],
        word('multiply')                     => %w[es_groovyJDKOperOverl Operator],
        word('each')                         => %w[es_groovyJDKMethods Function],
        word('call')                         => %w[es_groovyJDKMethods Function],
        word('inject')                       => %w[es_groovyJDKMethods Function],
        word('sort')                         => %w[es_groovyJDKMethods Function],
        word('print')                        => %w[es_groovyJDKMethods Function],
        word('println')                      => %w[es_groovyJDKMethods Function],
        word('getAt')                        => %w[es_groovyJDKMethods Function],
        word('putAt')                        => %w[es_groovyJDKMethods Function],
        word('size')                         => %w[es_groovyJDKMethods Function],
        word('push')                         => %w[es_groovyJDKMethods Function],
        word('pop')                          => %w[es_groovyJDKMethods Function],
        word('toList')                       => %w[es_groovyJDKMethods Function],
        word('getText')                      => %w[es_groovyJDKMethods Function],
        word('writeLine')                    => %w[es_groovyJDKMethods Function],
        word('eachLine')                     => %w[es_groovyJDKMethods Function],
        word('readLines')                    => %w[es_groovyJDKMethods Function],
        word('withReader')                   => %w[es_groovyJDKMethods Function],
        word('withStream')                   => %w[es_groovyJDKMethods Function],
        word('withWriter')                   => %w[es_groovyJDKMethods Function],
        word('withPrintWriter')              => %w[es_groovyJDKMethods Function],
        word('write')                        => %w[es_groovyJDKMethods Function],
        word('read')                         => %w[es_groovyJDKMethods Function],
        word('leftShift')                    => %w[es_groovyJDKMethods Function],
        word('withWriterAppend')             => %w[es_groovyJDKMethods Function],
        word('readBytes')                    => %w[es_groovyJDKMethods Function],
        word('splitEachLine')                => %w[es_groovyJDKMethods Function],
        word('newInputStream')               => %w[es_groovyJDKMethods Function],
        word('newOutputStream')              => %w[es_groovyJDKMethods Function],
        word('newPrintWriter')               => %w[es_groovyJDKMethods Function],
        word('newReader')                    => %w[es_groovyJDKMethods Function],
        word('newWriter')                    => %w[es_groovyJDKMethods Function],
        word('compareTo')                    => %w[es_groovyJDKMethods Function],
        word('next')                         => %w[es_groovyJDKMethods Function],
        word('previous')                     => %w[es_groovyJDKMethods Function],
        word('isCase')                       => %w[es_groovyJDKMethods Function],
        word('times')                        => %w[es_groovyJDKMethods Function],
        word('step')                         => %w[es_groovyJDKMethods Function],
        word('toInteger')                    => %w[es_groovyJDKMethods Function],
        word('upto')                         => %w[es_groovyJDKMethods Function],
        word('any')                          => %w[es_groovyJDKMethods Function],
        word('collect')                      => %w[es_groovyJDKMethods Function],
        word('dump')                         => %w[es_groovyJDKMethods Function],
        word('every')                        => %w[es_groovyJDKMethods Function],
        word('find')                         => %w[es_groovyJDKMethods Function],
        word('findAll')                      => %w[es_groovyJDKMethods Function],
        word('grep')                         => %w[es_groovyJDKMethods Function],
        word('inspect')                      => %w[es_groovyJDKMethods Function],
        word('invokeMethods')                => %w[es_groovyJDKMethods Function],
        word('join')                         => %w[es_groovyJDKMethods Function],
        word('getErr')                       => %w[es_groovyJDKMethods Function],
        word('getIn')                        => %w[es_groovyJDKMethods Function],
        word('getOut')                       => %w[es_groovyJDKMethods Function],
        word('waitForOrKill')                => %w[es_groovyJDKMethods Function],
        word('count')                        => %w[es_groovyJDKMethods Function],
        word('tokenize')                     => %w[es_groovyJDKMethods Function],
        word('asList')                       => %w[es_groovyJDKMethods Function],
        word('flatten')                      => %w[es_groovyJDKMethods Function],
        word('immutable')                    => %w[es_groovyJDKMethods Function],
        word('intersect')                    => %w[es_groovyJDKMethods Function],
        word('reverse')                      => %w[es_groovyJDKMethods Function],
        word('reverseEach')                  => %w[es_groovyJDKMethods Function],
        word('subMap')                       => %w[es_groovyJDKMethods Function],
        word('append')                       => %w[es_groovyJDKMethods Function],
        word('asWritable')                   => %w[es_groovyJDKMethods Function],
        word('eachByte')                     => %w[es_groovyJDKMethods Function],
        word('eachLine')                     => %w[es_groovyJDKMethods Function],
        word('eachFile')                     => %w[es_groovyJDKMethods Function],
        region("'es_groovyString'")          => %w[es_groovyString String],
        region("'es_groovyString")           => %w[es_groovyString String],
        region("'es_groovyString\\\\'")      => %w[es_groovyString String],
        region("'''es_groovyString'''")      => %w[es_groovyString String],
        region("'''es_groovyString")         => %w[es_groovyString String],
        region('"es_groovyString"')          => %w[es_groovyString String],
        region('"es_groovyString')           => %w[es_groovyString String],
        region('"es_groovyString\\\\"')      => %w[es_groovyString String],
        region('"""es_groovyString"""')      => %w[es_groovyString String],
        region('"""es_groovyString')         => %w[es_groovyString String],

        region('/\\*es_groovyComment\\*/')   => %w[es_groovyComment Comment],
        region('/\\* es_groovyComment \\*/') => %w[es_groovyComment Comment],
        region('/\\*es_groovyComment')       => %w[es_groovyComment Comment],
        region('/\\* es_groovyComment')      => %w[es_groovyComment Comment],
        region('/\\*\\*/')                   => %w[es_groovyComment Comment],

        word('checkout')                     => %w[es_jenkinsfileCoreStep Function],
        word('docker')                       => %w[es_jenkinsfileCoreStep Function],
        word('node')                         => %w[es_jenkinsfileCoreStep Function],
        word('scm')                          => %w[es_jenkinsfileCoreStep Function],
        word('sh')                           => %w[es_jenkinsfileCoreStep Function],
        word('stage')                        => %w[es_jenkinsfileCoreStep Function],
        word('parallel')                     => %w[es_jenkinsfileCoreStep Function],
        word('steps')                        => %w[es_jenkinsfileCoreStep Function],
        word('step')                         => %w[es_jenkinsfileCoreStep Function],
        word('tool')                         => %w[es_jenkinsfileCoreStep Function],
        word('post')                         => %w[es_jenkinsfileCoreStep Function],
        word('always')                       => %w[es_jenkinsfileCoreStep Function],
        word('changed')                      => %w[es_jenkinsfileCoreStep Function],
        word('failure')                      => %w[es_jenkinsfileCoreStep Function],
        word('success')                      => %w[es_jenkinsfileCoreStep Function],
        word('unstable')                     => %w[es_jenkinsfileCoreStep Function],
        word('aborted')                      => %w[es_jenkinsfileCoreStep Function]
      )
    end
  end
end
