# frozen_string_literal: true

class API::ESearch::Core
  attr_reader :editor

  def initialize(editor)
    @editor = editor
  end

  def search!(search_string)
    editor.press! ":call esearch#init()<Enter>#{search_string}<Enter>"
  end
end
