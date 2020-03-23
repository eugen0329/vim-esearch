# frozen_string_literal: true

# For testing opening entries of both window and quickfix output

module Helpers::Open
  extend RSpec::Matchers::DSL

  def tabpage_buffers_list
    editor.echo func('tabpagebuflist')
  end

  def tabpage_windows_list
    (1..editor.echo( func('tabpagewinnr', func('tabpagenr'), '$'))).to_a
  end

  def tabpages_list
    (1..editor.echo(func('tabpagenr', '$'))).to_a
  end
end
