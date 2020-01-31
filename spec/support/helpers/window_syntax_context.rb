# frozen_string_literal: true

module Helpers::WindowSyntaxContext
  extend RSpec::Matchers::DSL
  VIM_REGEXP_START_MATCH = '\\zs'
  VIM_REGEXP_END_MATCH = '\\ze'
  VIM_REGEXP_AVOID_MATCHING_FIRST_3_LINES = '\\%>3l'
  VIM_REGEXP_WORD_START = '\\<'
  VIM_REGEXP_WORD_END = '\\>'

  def word(text)
    [VIM_REGEXP_AVOID_MATCHING_FIRST_3_LINES,
     VIM_REGEXP_WORD_START,
     text,
     VIM_REGEXP_WORD_END].join
  end

  def region(text, at: nil)
    vim_regexp = text.dup

    if at
      vim_regexp.insert(at.end, VIM_REGEXP_END_MATCH) if at.end
      vim_regexp.insert(at.begin, VIM_REGEXP_START_MATCH) if at.begin
    end

    [VIM_REGEXP_AVOID_MATCHING_FIRST_3_LINES, vim_regexp].join
  end

  matcher :have_highligh_aliases do |expected|
    diffable

    match do
      highlight_names = esearch.editor.syntax_aliases_at(expected.keys)
      @actual = expected.keys.zip(highlight_names).to_h
      values_match?(expected, @actual)
    end

    description { 'have highlight aliases' }
  end

  matcher :have_line_numbers_highlight do |expected|
    attr_reader :actual, :expected

    diffable

    match do |code|
      line_numbers = code
                     .split("\n")
                     .each.with_index(1)
                     .reject { |line, _i| line.empty? }
                     .map { |_, line_number| line_number }

      location_regexps = line_numbers
        .map { |line_number| "^\\s\\+#{line_number}\\ze\\s" }

      highlight_names = esearch
                     .editor
                     .syntax_aliases_at(location_regexps)
                     .to_a

      @actual = line_numbers.zip(highlight_names).to_h
      @expected = line_numbers.zip([expected] * line_numbers.count).to_h

      values_match?(@expected, @actual)
    end
  end
end
