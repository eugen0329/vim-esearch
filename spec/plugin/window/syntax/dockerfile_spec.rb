# frozen_string_literal: true

require 'spec_helper'
require_relative 'setup_syntax_testing_shared_context'

describe 'esearch window context syntax', :window do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  describe 'json' do
    # blank line is kept intentionally to know whether the last verified line
    # corrupts LineNr virtual UI or not

    let(:source_file_content) do
      <<~SOURCE
      add
      arg
      cmd
      copy
      entrypoint
      env
      expose
      healthcheck
      label
      maintainer
      onbuild
      run
      shell
      stopsignal
      user
      volume
      workdir
      as

      ADD
      ARG
      CMD
      COPY
      ENTRYPOINT
      ENV
      EXPOSE
      HEALTHCHECK
      LABEL
      MAINTAINER
      ONBUILD
      RUN
      SHELL
      STOPSIGNAL
      USER
      VOLUME
      WORKDIR #es_dockerfileComment
      AS # es_dockerfileComment
      #es_dockerfileComment
      # es_dockerfileComment

      "es_dockerfileString"
      "es_dockerfileString
      "es_dockerfileString\\"

      SOURCE
    end
    let(:source_file) { file(source_file_content, 'Dockerfile') }

    include_context 'setup syntax testing'

    # 1. Verification is done in a single example for performance reasons (as
    # vim's +clientserver is too sluggish; it doesn't affect debuggability as
    # the matcher is diffable)
    # 2. Lines that can cause matching across line end (e.g. not terminated strings
    # or comments) are not groupped and scattered across source_file to cause as
    # more potential errors as possible
    it do
      is_expected.to have_highligh_aliases(
        word('add')                         => %w[es_dockerfileKeyword Keyword],
        word('arg')                         => %w[es_dockerfileKeyword Keyword],
        word('cmd')                         => %w[es_dockerfileKeyword Keyword],
        word('copy')                        => %w[es_dockerfileKeyword Keyword],
        word('entrypoint')                  => %w[es_dockerfileKeyword Keyword],
        word('env')                         => %w[es_dockerfileKeyword Keyword],
        word('expose')                      => %w[es_dockerfileKeyword Keyword],
        word('healthcheck')                 => %w[es_dockerfileKeyword Keyword],
        word('label')                       => %w[es_dockerfileKeyword Keyword],
        word('maintainer')                  => %w[es_dockerfileKeyword Keyword],
        word('onbuild')                     => %w[es_dockerfileKeyword Keyword],
        word('run')                         => %w[es_dockerfileKeyword Keyword],
        word('shell')                       => %w[es_dockerfileKeyword Keyword],
        word('stopsignal')                  => %w[es_dockerfileKeyword Keyword],
        word('user')                        => %w[es_dockerfileKeyword Keyword],
        word('volume')                      => %w[es_dockerfileKeyword Keyword],
        word('workdir')                     => %w[es_dockerfileKeyword Keyword],
        word('as')                          => %w[es_dockerfileKeyword Keyword],

        word('ADD')                         => %w[es_dockerfileKeyword Keyword],
        word('ARG')                         => %w[es_dockerfileKeyword Keyword],
        word('CMD')                         => %w[es_dockerfileKeyword Keyword],
        word('COPY')                        => %w[es_dockerfileKeyword Keyword],
        word('ENTRYPOINT')                  => %w[es_dockerfileKeyword Keyword],
        word('ENV')                         => %w[es_dockerfileKeyword Keyword],
        word('EXPOSE')                      => %w[es_dockerfileKeyword Keyword],
        word('HEALTHCHECK')                 => %w[es_dockerfileKeyword Keyword],
        word('LABEL')                       => %w[es_dockerfileKeyword Keyword],
        word('MAINTAINER')                  => %w[es_dockerfileKeyword Keyword],
        word('ONBUILD')                     => %w[es_dockerfileKeyword Keyword],
        word('RUN')                         => %w[es_dockerfileKeyword Keyword],
        word('SHELL')                       => %w[es_dockerfileKeyword Keyword],
        word('STOPSIGNAL')                  => %w[es_dockerfileKeyword Keyword],
        word('USER')                        => %w[es_dockerfileKeyword Keyword],
        word('VOLUME')                      => %w[es_dockerfileKeyword Keyword],
        word('WORKDIR')                     => %w[es_dockerfileKeyword Keyword],
        word('AS')                          => %w[es_dockerfileKeyword Keyword],

        region('# es_dockerfileComment')    => %w[es_dockerfileComment Comment],
        region('#es_dockerfileComment')     => %w[es_dockerfileComment Comment],

        region('"es_dockerfileString"')     => %w[es_dockerfileString String],
        region('"es_dockerfileString')      => %w[es_dockerfileString String],
        region('"es_dockerfileString\\\\"') => %w[es_dockerfileString String],
      )
    end
  end
end

