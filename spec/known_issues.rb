# frozen_string_literal: true

require 'support/known_issues'

# https://relishapp.com/rspec/rspec-core/docs/metadata/user-defined-metadata
KnownIssues.allow_tests_to_fail_matching_by_metadata do
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
  pending! '/(?<name>', /reported_errors/, adapter: :pt, matching: :regexp
  # TODO: output should handle status codes from adapters
  pending! '/(?<=',     /reported_errors/, adapter: :pt, matching: :regexp

  # TODO: implement support for later versions with --pcre2
  # https://github.com/BurntSushi/ripgrep/blob/master/CHANGELOG.md
  pending! '/(?<=',     /reported_errors/, adapter: :rg, matching: :regexp
  pending! '/(?<name>', /reported_errors/, adapter: :rg, matching: :regexp

  # TODO: investigate
  pending! '/1\d+3/', /has_reported_a_single_result\?/, :osx, adapter: :git, matching: :regexp
end
