# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'

#  TODO rewrite
class API::ESearch::StubbedOutput
  include VimlValue::SerializationHelpers

  attr_reader :editor

  def initialize(editor)
    @editor = editor
  end

  def calls_history
    editor.echo func('get', var('g:'), 'esearch#out#stubbed#calls_history', [])
  end

  def reset_calls_history!
    editor.command!('let g:esearch#out#stubbed#calls_history = []')
  end

  def echo_calls_history
    editor.echo var('g:esearch#util#echo_calls_history')
  end
end
