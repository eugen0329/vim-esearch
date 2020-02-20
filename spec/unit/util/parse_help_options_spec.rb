# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#util' do
  include VimlValue::SerializationHelpers
  include Helpers::FileSystem

  context '#parse_help_options' do
    shared_examples 'adapter help' do |adapter, path: adapter, arg: '--help'|
      let(:option_regexp) { /\A-{1,2}[a-zA-Z0-9][-a-zA-Z0-9]*/ }
      subject do
        VimlValue.load(vim.echo("esearch#util#parse_help_options('#{path} --help')"))
      end

      it "for command `#{adapter} #{arg}` outputs seemingly valid results" do
        is_expected
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
