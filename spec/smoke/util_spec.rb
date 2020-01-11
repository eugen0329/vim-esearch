# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

describe 'Smoke of esearch#util' do
  include Helpers::FileSystem

  around { |e| esearch.editor.with_ignore_cache(&e) }

  context '#parse_help_options' do
    shared_examples 'adapter help' do |adapter, path: adapter, arg: '--help'|
      let(:result) { esearch.editor.raw_echo("esearch#util#parse_help_options('#{path} --help')") }
      let(:deserialized_result) { API::Editor::Serialization::YAMLDeserializer.new.deserialize(result) }
      let(:option_regexp) { /\A-{1,2}[a-zA-Z0-9][-a-zA-Z0-9]*/ }

      it "for command `#{adapter} #{arg}` outputs seemingly valid results" do
        expect(deserialized_result)
          .to  be_present
          .and be_a(Hash)
          .and all(satisfy { |key, _| key =~ option_regexp })
      end
    end

    include_examples 'adapter help', 'ag',       arg: '--help'
    include_examples 'adapter help', 'ack',      arg: '--help'
    include_examples 'adapter help', 'git grep', arg: '-h'
    include_examples 'adapter help', 'grep',     arg: '-h'
    include_examples 'adapter help', 'pt',       arg: '--help', path: Configuration.pt_path
    include_examples 'adapter help', 'rg',       arg: '--help', path: Configuration.rg_path
  end
end
