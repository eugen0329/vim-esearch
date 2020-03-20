# frozen_string_literal: true

module Helpers::Preview
  extend RSpec::Matchers::DSL

  define_negated_matcher :not_to_change, :change
  define_negated_matcher :not_change, :change

  def window_handles
    editor.echo func('nvim_list_wins')
  end

  def window_local_highlights
    map_windows_options('winhighlight')
  end

  def default_highlight
    ''
  end

  def map_windows_options(name)
    editor.echo func('map', func('nvim_list_wins'), "nvim_win_get_option(v:val, #{name.dump})")
  end
end
