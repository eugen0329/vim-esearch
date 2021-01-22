# frozen_string_literal: true

class API::ESearch::Core
  attr_reader :editor

  def initialize(editor)
    @editor = editor
  end

  def search!(search_string, **kwargs)
    editor.press! ":call esearch#init(#{VimlValue.dump(kwargs)})<enter>#{search_string}<enter>"
  end

  def input!(search_string, **kwargs)
    editor.press! ":call esearch#init(#{VimlValue.dump(kwargs)})<enter>#{search_string}"
  end
end
