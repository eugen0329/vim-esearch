# frozen_string_literal: true

class API::VisualMulti
  include VimlValue::SerializationHelpers

  LEADER = '\\\\'

  attr_reader :editor

  def initialize(editor)
    @editor = editor
  end

  def regions
    editor.echo(var('b:VM_Selection.Regions'))
  end
end
