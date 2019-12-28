# frozen_string_literal: true

class API::ESearch::Core
  include API::Mixins::VimTypes

  attr_reader :editor

  def initialize(editor)
    @editor = editor
  end

  def search!(search_string, **kwargs)
    editor.press! ":call esearch#init(#{search_args(**kwargs)})<Enter>#{search_string}<Enter>"
  end

  private

  def search_args(**kwargs)
    return nil if kwargs.blank?

    to_vim_dict(kwargs)
  end
end
