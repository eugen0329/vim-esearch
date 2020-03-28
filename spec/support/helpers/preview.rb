# frozen_string_literal: true

module Helpers::Preview
  extend RSpec::Matchers::DSL
  include Helpers::Open

  define_negated_matcher :not_to_change, :change
  define_negated_matcher :not_change, :change
  define_negated_matcher :not_include, :include

  shared_examples 'enable swaps' do
    before do
      editor.command <<~VIML
        set swapfile directory=#{test_directory} updatecount=1
        set updatecount=1
      VIML
    end
    after do
      editor.command <<~VIML
        set noswapfile
        set updatecount=0
      VIML
    end
  end

  def window_highlights
    map_windows_options('winhighlight')
  end

  def map_windows_options(name)
    editor.echo func('map', func('nvim_list_wins'), "nvim_win_get_option(v:val, #{name.dump})")
  end

  def default_highlight
    ''
  end

  def current_window_highlight
    editor.echo func('nvim_win_get_option', func('nvim_get_current_win'), 'winhighlight')
  end

  def window_height(handle)
    editor.echo(func('nvim_win_get_height', handle))
  end

  def window_width(handle)
    editor.echo(func('nvim_win_get_width', handle))
  end

  def close_popup_and_open_window
    change { windows }
      .and not_to_change { windows.count }
  end

  def stay_in_buffer
    not_to_change { editor.current_buffer_name }
  end

  def close_window(handle)
    change { windows }
      .to(not_include(handle))
  end

  matcher :have_default_window_highlights do
    match do
      @actual = window_highlights
      @expected = [default_highlight] * window_highlights.count
      values_match? @expected, @actual
    end
  end

  matcher :have_popup_highlight do |highlight|
    match do
      @actual = window_highlights
      @expected = [default_highlight] * (window_highlights.count - 1) + [highlight]
      values_match? @expected, @actual
    end
  end
end
