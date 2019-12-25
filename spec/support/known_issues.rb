# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/array/extract_options'

class KnownIssues
  Issue = Struct.new(:allow_fail_method,
                     :description_pattern,
                     :exception_pattern,
                     :metadata)

  class_attribute :issues, default: []

  def self.allow_tests_to_fail_matching_by_tags(&block)
    new.instance_eval(&block)
  end

  def self.mark_example_pending_if_known_issue(spec)
    yield
  rescue Exception => e # rubocop:disable Lint/RescueException
    description = RSpec.current_example.description
    metadata = RSpec.current_example.metadata

    issue = issues.find do |i|
      i.metadata <= metadata &&
        description.include?(i.description_pattern) &&
        e.message =~ /#{i.exception_pattern}/
    end
    if issue
      spec.public_send(issue.allow_fail_method,
                       "known issue with #{issue.description_pattern} #{issue.metadata}")
    end

    raise
  end

  def pending!(description_pattern, exception_pattern, *metadata)
    issues << Issue.new(:pending,
                        description_pattern,
                        exception_pattern,
                        normalize_metadata(metadata))
  end

  def skip!(description_pattern, exception_pattern, *metadata)
    issues << Issue.new(:skip,
                        description_pattern,
                        exception_pattern,
                        normalize_metadata(metadata))
  end

  private

  def normalize_metadata(metadata)
    metadata.extract_options!.merge(metadata.map { |key| [key, true] }.to_h)
  end
end
