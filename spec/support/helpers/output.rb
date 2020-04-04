# frozen_string_literal: true

module Helpers::Output
  extend RSpec::Matchers::DSL

  def finish_search_in_files(filenames)
    have_search_started
      .and have_search_finished
      .and have_not_reported_errors
      .and have_results_in_files(filenames)
  end

  matcher :have_outputted_results do |count:|
    match do |esearch|
      @actual = esearch.output.entries.to_a.count
      @actual == count
    end
  end

  matcher :have_not_reported_errors do
    match(&:has_not_reported_errors?)

    failure_message do |esearch|
      ['expected to have_not_reported_errors,',
       "got output:\n\t#{esearch.output.errors.to_a.join("\n")}"].join(' ')
    end
  end

  matcher :have_results_in_files do |files|
    match do |esearch|
      @expected = files
      @actual = esearch.output.entries.map(&:relative_path)
      values_match?(@expected.sort, @actual.sort)
    end

    failure_message do
      "expected to have results in \n#{@expected},\ngot\n#{@actual}"
    end
  end
end
