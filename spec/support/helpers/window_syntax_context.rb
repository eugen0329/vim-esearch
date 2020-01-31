# frozen_string_literal: true

module Helpers::WindowSyntaxContext
  extend RSpec::Matchers::DSL

  # wrap with \bname\b and allow matches only after 3d line
  def word(name)
    "\\%>3l\\<#{name}\\>"
  end

  # allow matches only after 3d line
  def region(text)
    "\\%>3l#{text}"
  end

  matcher :have_highligh_aliases do |expected|
    diffable

    match do
      syntax_names = esearch.editor.inspect_syntax(expected.keys)
      @actual = expected.keys.zip(syntax_names).to_h
      values_match?(expected, @actual)
    end
  end

  matcher :have_line_numbers_highlight do |expected|
    attr_reader :actual, :expected

    diffable

    match do |code|
      line_numbers = code
                     .split("\n")
                     .each.with_index(1)
                     .reject { |l, _i| l.empty? }
                     .map { |_, i| i }

      regexps = line_numbers.map { |i| "^\\s\\+#{i}\\ze\\s" }

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
