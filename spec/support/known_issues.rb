# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'

class KnownIssues
  Issue = Struct.new(
    :description_substring,
    :exception_pattern,
    :meta
  )

  class_attribute :pending_issues, default: []
  class_attribute :skip_issues,    default: []
  class_attribute :random_issues,  default: []

  def self.allow_tests_to_fail_matching_by_metadata(config = RSpec.configuration, &block)
    new.instance_eval(&block)
    initialize_skip_hooks!(config)
    initialize_random_failure_hooks!(config)
  end

  def self.initialize_skip_hooks!(config)
    skip_issues.each do |issue|
      config.prepend_before(:example, **hook_filters(issue)) do
        skip "known issue with #{issue.description_substring} #{issue.meta}"
      end
    end
  end

  def self.initialize_random_failure_hooks!(config)
    random_issues.each do |issue|
      config.prepend_after(:example, **hook_filters(issue)) do |example|
        if example.exception.nil?
          skip "random success with #{issue.description_substring.inspect} #{issue.meta}"
        elsif  example.exception.message.match?(issue.exception_pattern)
          skip "random failure with #{issue.description_substring.inspect} #{issue.meta}"
        end
      end
    end
  end

  def self.mark_example_pending_if_known_issue(example)
    yield
  rescue Exception => e # rubocop:disable Lint/RescueException
    description = RSpec.current_example.full_description
    metadata = RSpec.current_example.metadata
    issue = pending_issues.find do |i|
      i.meta <= metadata &&
        description.include?(i.description_substring) &&
        e.message.match?(i.exception_pattern)
    end
    example.pending "known issue with #{issue.description_substring.inspect} #{issue.meta}" if issue

    raise
  end

  def self.hook_filters(issue)
    issue.meta.merge(
      full_description: /#{Regexp.quote(issue.description_substring)}/
    )
  end

  def pending!(description_substring, exception_pattern, *meta_args, **meta_kwargs)
    pending_issues << Issue.new(description_substring,
      exception_pattern,
      normalized_meta(meta_args, meta_kwargs))
  end

  def skip!(description_substring, *meta_args, **meta_kwargs)
    skip_issues << Issue.new(description_substring,
      nil,
      normalized_meta(meta_args, meta_kwargs))
  end

  def random_failure!(description_substring, exception_pattern, *meta_args, **meta_kwargs)
    random_issues << Issue.new(description_substring,
      exception_pattern,
      normalized_meta(meta_args, meta_kwargs))
  end

  private

  def normalized_meta(meta_args, meta_kwargs)
    meta_kwargs.merge(meta_args.map { |key| [key, true] }.to_h)
  end
end
