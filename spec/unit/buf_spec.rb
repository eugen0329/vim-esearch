# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#buf' do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers

  describe 'esearch#buf#find' do
    context 'when filename contains special characters' do
      let(:filename) { 'asd' }
      let(:filename) { "%#$^\\$\\^{}\\{\\}#{'\\' * 3}{1,2\\},\\n{}[foo][bar[]]\\[\\]?\\?*\\*.\\. \\ %#\\%\\#" }

      let(:files) { [file('', filename.gsub('\\', '\\\\\\\\'))] }
      let!(:test_directory) { directory(files).persist! }

      before do
        editor.cd! test_directory
        pending 'TODO'
      end

      context 'when listed' do
        before do
          editor.edit! files.first.to_s.gsub(/[#%]/, '\\\\\0')
        end

        it { expect(editor.echo(func('esearch#buf#find', filename))).to be > 0 }
      end

      context 'when hidden' do
        before do
          editor.edit! files.first.to_s.gsub(/[#%]/, '\\\\\0')
          editor.command! 'enew'
        end

        it { expect(editor.echo(func('esearch#buf#find', filename))).to be > 0 }
      end
    end
  end
end
