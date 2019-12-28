# frozen_string_literal: true

class API::ESearch::Core
  include TaggedLogging
  include API::Mixins::VimTypes

  attr_reader :editor

  def initialize(editor)
    @editor = editor
  end

  def search!(search_string, **kwargs)
    keyboard = ":call esearch#init(#{search_args(**kwargs)})<Enter>#{search_string}<Enter>"
    log_debug { keyboard }
    editor.press! keyboard
  end

  private

  def search_args(**kwargs)
    return nil if kwargs.blank?

    to_vim_dict(kwargs)
  end
end
