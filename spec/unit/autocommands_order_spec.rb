# frozen_string_literal: true

require 'spec_helper'

describe '' do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers

  let(:files) do
    [file('', 'from.txt'),
     file('', 'to.txt'),]
  end
  let!(:test_directory) { directory(files).persist! }

  let!(:available_events) do
    editor
      .autocommands_listed_in_manual
      .reject { |c| c.end_with?('Cmd') || c == 'User' }
  end

  let(:order) do
    editor
      .echo(var('g:_order'))
      .reject { |e| %w[SafeState SafeStateAgain CursorMoved CursorHold FocusGained].include?(e.last) }
  end

  before do
    editor.edit! files.first
    editor.command! 'let g:_order = []'
    editor.command! [
      'augroup AutocmdsTest',
      'au!',
      'augroup END',
    ].join('|')
    available_events.each do |a|
      editor.command! "au AutocmdsTest #{a} * call add(g:_order, [expand('%'), '#{a}'])"
    end
  end

  after do
    editor.command! 'au! AutocmdsTest | let g:_order = []'
    editor.cleanup!
  end

  it 'runs commands on edit' do
    editor.edit! files.last

    expect(order).to match_array([[files.first.to_s, 'BufNew'],
                                  [files.first.to_s, 'BufAdd'],
                                  [files.first.to_s, 'BufCreate'],
                                  [files.first.to_s, 'BufLeave'],
                                  [files.first.to_s, 'BufWinLeave'],
                                  [files.first.to_s, 'BufUnload'],
                                  [files.last.to_s,  'BufReadPre'],
                                  [files.last.to_s,  'Syntax'],
                                  [files.last.to_s,  'FileType'],
                                  [files.last.to_s,  'BufRead'],
                                  [files.last.to_s,  'BufReadPost'],
                                  [files.last.to_s,  'BufEnter'],
                                  [files.last.to_s,  'BufWinEnter'],])
  end

  it "doesn't run autocommands when noautocmd edit is used" do
    editor.command "noautocmd edit #{files.last}"

    expect(order).to match_array([])
  end

  it 'hooks extra autocommands on BufReadPre and BufRead' do
    editor.command "noautocmd edit #{files.last}"
    editor.command 'doau BufReadPre'
    editor.command 'doau BufRead'

    expect(order).to match_array([[files.last.to_s, 'BufReadPre'],
                                  [files.last.to_s, 'Syntax'],
                                  [files.last.to_s, 'FileType'],
                                  [files.last.to_s, 'BufRead'],
                                  [files.last.to_s, 'BufReadPost'],])
  end
end
