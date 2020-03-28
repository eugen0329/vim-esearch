# frozen_string_literal: true

# For testing opening entries of both window and quickfix output

module Helpers::Open
  extend RSpec::Matchers::DSL

  def tabpage_buffers_list
    editor.echo func('tabpagebuflist')
  end

  def tabpage_windows_list
    (1..editor.echo(func('tabpagewinnr', func('tabpagenr'), '$'))).to_a
  end

  def tabpages_list
    (1..editor.echo(func('tabpagenr', '$'))).to_a
  end

  def start_editing(path)
    change { editor.current_buffer_name }
      .to(path.to_s)
  end

  def windows
    editor.echo func('nvim_list_wins')
  end

  def open_window(path)
    change { editor.current_buffer_name }
      .to end_with path.to_s
  end

  def open_tab(path)
    change { tabpages_list.count }
      .by(1)
      .and change { editor.current_buffer_name }
      .to end_with path
  end
end
