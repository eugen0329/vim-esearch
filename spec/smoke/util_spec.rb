# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

describe 'Smoke of esearch#util' do
  include Helpers::FileSystem

  around { |e| esearch.editor.with_ignore_cache(&e) }

  context '#parse_help_options' do
    shared_examples 'adapter --help' do |adapter, path: adapter|
      let(:result) { esearch.editor.echo("esearch#util#parse_help_options('#{path} --help')") }
      let(:deserialized_result) { YAML.safe_load(result) }
      let(:option_regexp) { /\A-{1,2}[a-zA-Z0-9][-a-zA-Z0-9]*/ }

      it "for command `#{adapter} --help` outputs seemingly valid results" do
        expect(deserialized_result)
          .to  be_present
          .and be_a(Hash)
          .and all(satisfy { |key, _| key =~ option_regexp })
      end
    end

    include_examples 'adapter --help', :ag
    include_examples 'adapter --help', :ack
    include_examples 'adapter --help', :git
    include_examples 'adapter --help', :grep
    include_examples 'adapter --help', :pt
    include_examples 'adapter --help', :rg, Configuration.bin_dir.join('rg-11.0.2')
  end
end
