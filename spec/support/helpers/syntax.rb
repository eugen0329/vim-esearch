# frozen_string_literal: true

module Helpers::Syntax
  extend RSpec::Matchers::DSL

  matcher :have_highlights do |expected|
    diffable

    match do
      syntax_names = esearch.editor.inspect_syntax(expected.keys)
      @actual = expected.keys.zip(syntax_names).to_h
      values_match?(expected, @actual)
    end
  end

  matcher :have_line_numbers_highlight do |expected|
    diffable
    attr_reader :actual, :expected

    match do |code|
      line_numbers = code
        .split("\n")
        .each.with_index(1)
        .reject { |l, i| l.empty? }
        .map { |_, i| i }

      regexps = line_numbers.map { |i|  "^\\s\\+#{i}\\ze\\s" }

      syntax_names = esearch
        .editor
        .detailed_inspect_syntax(regexps)
        .to_a

      @actual = line_numbers.zip(syntax_names).to_h
      @expected = line_numbers.zip([expected] * line_numbers.count).to_h

      values_match?(@expected, @actual)
    end
  end

end
