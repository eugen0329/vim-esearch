# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'sh' do
    let(:source_file_content) do
      <<~SOURCE
        break
        cd
        chdir
        continue
        eval
        exec
        exit
        kill
        newgrp
        pwd
        read
        readonly
        return
        shift
        test
        trap
        ulimit
        umask
        wait

        'string'
        "string"
        "string\\n"

        $deref
        $1

        "unterminated string
        'unterminated string

        case
        esac
        do
        done
        for
        in
        if
        fi
        until
        while
      SOURCE
    end
    let(:source_file) { file(source_file_content, 'main.sh') }
    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('break')                  => %w[es_shStatement Statement],
        word('cd')                     => %w[es_shStatement Statement],
        word('chdir')                  => %w[es_shStatement Statement],
        word('continue')               => %w[es_shStatement Statement],
        word('eval')                   => %w[es_shStatement Statement],
        word('exec')                   => %w[es_shStatement Statement],
        word('exit')                   => %w[es_shStatement Statement],
        word('kill')                   => %w[es_shStatement Statement],
        word('newgrp')                 => %w[es_shStatement Statement],
        word('pwd')                    => %w[es_shStatement Statement],
        word('read')                   => %w[es_shStatement Statement],
        word('readonly')               => %w[es_shStatement Statement],
        word('return')                 => %w[es_shStatement Statement],
        word('shift')                  => %w[es_shStatement Statement],
        word('test')                   => %w[es_shStatement Statement],
        word('trap')                   => %w[es_shStatement Statement],
        word('ulimit')                 => %w[es_shStatement Statement],
        word('umask')                  => %w[es_shStatement Statement],
        word('wait')                   => %w[es_shStatement Statement],

        region('"string"')             => %w[es_shDoubleQuote String],
        region('"string\\\\n"')        => %w[es_shDoubleQuote String],
        region("'string'")             => %w[es_shSingleQuote String],

        region('\\$deref')             => %w[es_shDerefSimple PreProc],
        region('\\$1')                 => %w[es_shDerefSimple PreProc],

        region("'unterminated string") => %w[es_shSingleQuote String],
        region('"unterminated string') => %w[es_shDoubleQuote String],

        word('case')                   => %w[es_shKeyword Keyword],
        word('esac')                   => %w[es_shKeyword Keyword],
        word('do')                     => %w[es_shKeyword Keyword],
        word('done')                   => %w[es_shKeyword Keyword],
        word('for')                    => %w[es_shKeyword Keyword],
        word('in')                     => %w[es_shKeyword Keyword],
        word('if')                     => %w[es_shKeyword Keyword],
        word('fi')                     => %w[es_shKeyword Keyword],
        word('until')                  => %w[es_shKeyword Keyword],
        word('while')                  => %w[es_shKeyword Keyword]
      )
    end
  end
end
