# frozen_string_literal: true

require 'support/known_issues'

KnownIssues.allow_tests_to_fail_matching_by_tags do
  pending! '[[:digit:]]', /position_inside_file/, adapter: :grep, matching: :regexp
  pending! '\d{2}',       /position_inside_file/, adapter: :grep, matching: :regexp
  pending! 'a{2}',        /position_inside_file/, adapter: :grep, matching: :regexp
  pending! '/(?:',        /position_inside_file/, adapter: :grep, matching: :regexp
  pending! '/(?<=',       /position_inside_file/, adapter: :grep, matching: :regexp
  pending! '(?<name>',    /position_inside_file/, adapter: :grep, matching: :regexp
  pending! '(?P<name>',   /position_inside_file/, adapter: :grep, matching: :regexp

  pending! '[[:digit:]]{2}', /position_inside_file/, adapter: :git, matching: :regexp
  pending! '\d{2}',          /position_inside_file/, adapter: :git, matching: :regexp
  pending! 'a{2}',           /position_inside_file/, adapter: :git, matching: :regexp
  pending! '/(?:',           /position_inside_file/, adapter: :git, matching: :regexp
  pending! '/(?<=',          /position_inside_file/, adapter: :git, matching: :regexp
  pending! '/(?<name>',      /position_inside_file/, adapter: :git, matching: :regexp
  pending! '(?P<name>',      /position_inside_file/, adapter: :git, matching: :regexp

  # https://github.com/google/re2/wiki/Syntax
  pending! '/(?<=',     /reported_errors/, adapter: :pt, matching: :regexp
  pending! '/(?<name>', /reported_errors/, adapter: :pt, matching: :regexp
end
