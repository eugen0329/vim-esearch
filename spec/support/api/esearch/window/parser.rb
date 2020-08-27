# frozen_string_literal: true

require 'ostruct'

class API::ESearch::Window::Parser
  attr_reader :editor

  def initialize(editor)
    @editor = editor
  end

  def header_finished?
    header_parser.finished?
  end

  def header_running?
    header_parser.running?
  end

  def header
    header_parser.parse
  end

  def entries
    entries_parser.parse
  end

  def header_parser
    @header_parser ||= API::ESearch::Window::HeaderParser.new(editor)
  end

  def entries_parser
    @entries_parser ||= API::ESearch::Window::EntriesParser.new(editor)
  end
end
