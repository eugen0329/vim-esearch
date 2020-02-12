# frozen_string_literal: true

module Helpers::Changes
  extend RSpec::Matchers::DSL

  def unknown
    -1
  end

  matcher :have_payload do |id, from, to|
    diffable

    attr_reader :expected

    match do |event|
      @expected = {
        'id'    => id,
        'line1' => from.begin,
        'line2' => to.begin,
        'col1'  => from.end,
        'col2'  => to.end
      }.compact
      @actual = event.slice(*@expected.keys)

      values_match?(@expected, @actual)
    end
  end

  matcher :eq_event do |expected_event|
    diffable

    attr_reader :expected

    match do |actual|
      id, l1, l2 = expected_event.split(' ')
      line1, col1 = l1.split(':').map do |i|
        next i if i == 'UNKNOWN'

        i&.to_i
      end
      if l2
        line2, col2 = l2.split(':').map do |i|
          next i if i == 'UNKNOWN'

          i&.to_i
        end
      end

      @expected = {'id'    => id,
                   'line1' => line1,
                   'col1'  => col1,
                   'line2' => line2,
                   'col2'  => col2}.compact
      values_match?(@expected, actual)
    end
  end
end
