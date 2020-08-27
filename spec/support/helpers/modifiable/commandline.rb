# frozen_string_literal: true

module Helpers::Modifiable::Commandline
  extend RSpec::Matchers::DSL

  matcher :change_entries_text do |*entries, timeout: 1|
    include API::Mixins::BecomeTruthyWithinTimeout

    supports_block_expectations

    match do |block|
      @before = reloaded_text(entries)
      block.call

      @changed = became_truthy_within?(timeout) do
        @after = reloaded_text(entries)
        @before != @after
      end
      return false unless @changed

      if @to
        @changed_to_expected = became_truthy_within?(timeout) do
          @after = reloaded_text(entries)
          values_match?(@to, @after)
        end
        return false unless @changed_to_expected
      end

      true
    end

    def reloaded_text(entries)
      esearch.output.reloaded_entries!(entries).map(&:result_text)
    end

    chain :to do |to|
      @to = to
    end

    failure_message do
      msg = "expected to change #{@before.inspect}"
      msg += " to #{@to.inspect}, got #{@after.inspect}" if @to
      msg
    end
  end

  define_negated_matcher :not_to_change_entries_text, :change_entries_text
end
