# frozen_string_literal: true

class API::ESearch::Window::HeaderParser
  HEADER_REGEXP = /Matches in (?<lines_count>\d+) lines?, (?<files_count>\d+) files?/.freeze

  attr_reader :editor

  def initialize(editor)
    @editor = editor
  end

  def parse
    return OpenStruct.new if header_line !~ HEADER_REGEXP

    OpenStruct.new(header_line.match(HEADER_REGEXP).named_captures.transform_values(&:to_i))
  end

  def finished?
    header_line.match?(HEADER_REGEXP) && header_line.match?(/\. Finished\.\z/)
  end

  def running?
    header_line.match?(HEADER_REGEXP) && !header_line.match?(/\. Finished\.\z/)
  end

  def errors?
    header_line.match?(/\AERRORS from/)
  end

  private

  def header_line
    editor.lines.first
  end
end
