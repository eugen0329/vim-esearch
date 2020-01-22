module Helpers::Errors
  extend RSpec::Matchers::DSL

  matcher :have_not_reported_errors do
    match(&:has_not_reported_errors?)

    failure_message do |esearch|
      ["expected to have_not_reported_errors,",
      "got output:\n\t#{esearch.output.errors.to_a.join("\n")}"].join(' ')
    end
  end
end
