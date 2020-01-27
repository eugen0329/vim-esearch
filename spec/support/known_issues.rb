# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/array/extract_options'

class KnownIssues
  Issue = Struct.new(:allow_fail_method,
                     :description_pattern,
                     :exception_pattern,
                     :metadata)

  class_attribute :pending_issues, default: []
  class_attribute :skip_issues, default: []

  def self.allow_tests_to_fail_matching_by_metadata(&block)
    new.instance_eval(&block)

    skip_issues.find do |issue|
      meta = {
        full_description: /#{Regexp.quote(issue.description_pattern)}/,
        **issue.metadata
      }

      RSpec.configuration.prepend_before(:each, **meta) do
        skip "known issue with #{issue.description_pattern} #{issue.metadata}"
      end
    end
  end

  def self.mark_example_pending_if_known_issue(spec)
    yield
  rescue Exception => e # rubocop:disable Lint/RescueException
    issue = pending_issues.find do |i|
      i.metadata <= metadata &&
        description.include?(i.description_pattern) &&
        e.message.match?(i.exception_pattern)
    end
    if issue
      spec.public_send(issue.allow_fail_method,
                       "known issue with #{issue.description_pattern} #{issue.metadata}")
    end

    raise
  end

  def pending!(description_pattern, exception_pattern, *metadata)
    pending_issues << Issue.new(:pending,
                        description_pattern,
                        exception_pattern,
                        normalize_metadata(metadata))
  end

  def skip!(description_pattern, exception_pattern, *metadata)
    skip_issues << Issue.new(:skip,
                        description_pattern,
                        exception_pattern,
                        normalize_metadata(metadata))
  end

  private

  def normalize_metadata(metadata)
    metadata.extract_options!.merge(metadata.map { |key| [key, true] }.to_h)
  end
end
