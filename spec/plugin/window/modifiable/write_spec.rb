# frozen_string_literal: true

require 'spec_helper'

describe 'Writing in modifiable mode' do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Modifiable

  include_context 'setup modifiable testing'

  # TODO: add more tests
  it do
    contexts[0].entries[-1].locate!
    editor.send_keys 'Azzz', :escape
    contexts[1].entries[0].locate!
    editor.send_keys 'dip'
    contexts[2].entries[0].locate!
    editor.send_keys 'dd'
    editor.send_keys_separately ':write', :enter, 'y'

    expect(editor.current_buffer_name).to eq(contexts[2].name)
    expect(editor.lines.to_a).to eq(contexts[2].content[1..])
    expect(editor).to be_modified

    editor.locate_buffer! contexts[1].name
    expect(editor.lines.to_a).to eq([''])
    expect(editor).to be_modified

    editor.locate_buffer! contexts[0].name
    expect(editor.lines.to_a)
      .to eq(contexts[0].content[..-2] + [contexts[0].content[-1] + 'zzz'])
    expect(editor).to be_modified
  end
end
