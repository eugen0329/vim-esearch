# frozen_string_literal: true

RSpec::Matchers.define :have_not_reported_errors do
  match do |esearch|
    esearch.has_not_reported_errors?
  end

  failure_message do |esearch|
    "expected to have_not_reported_errors, got output:\n\t#{esearch.output.errors.to_a.join("\n")}"
  end
end
