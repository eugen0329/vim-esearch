# frozen_string_literal: true

require 'support/known_issues'

# Match examples by user defined metadata and mark it with skip or pending:
#   https://relishapp.com/rspec/rspec-core/docs/metadata/user-defined-metadata
# The same approach is used in other repos (ex. JRuby) to avoid overcrowding
# example bodies with inline if-condition-then-pending and to keep all the
# pending examples info in one place. In addition, only exceptions matching
# exception_pattern are handled to avoid false positives.
#
# Usage:
#   pending!        description_substring, exception_pattern, **other_metadata
#   skip!           description_substring, **other_metadata
#   random_failure! description_substring, exception_pattern, **other_metadata
#
# #skip! and pending! follow RSpec semantics
# #random_failure! works like pending, but won't fail if an example is succeeded
KnownIssues.allow_tests_to_fail_matching_by_metadata do
  # Aren't implemented by grep
  pending! '[[:digit:]]', /position_inside_file/, adapter: :grep, matching: :regexp
  pending! '\d{2}',       /position_inside_file/, adapter: :grep, matching: :regexp
  pending! 'a{2}',        /position_inside_file/, adapter: :grep, matching: :regexp
  pending! '/(?:',        /position_inside_file/, adapter: :grep, matching: :regexp
  pending! '/(?<=',       /position_inside_file/, adapter: :grep, matching: :regexp
  pending! '(?<name>',    /position_inside_file/, adapter: :grep, matching: :regexp
  pending! '(?P<name>',   /position_inside_file/, adapter: :grep, matching: :regexp

  # Aren't implemented by git-grep
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
  skip! '/3\d+5/', :osx, adapter: :git, matching: :regexp
  skip! '/3\d*5/', :osx, adapter: :git, matching: :regexp

  # TODO: investigate
  random_failure! 'aborts on search restart', /.*/, :osx, backend: :vimproc
  random_failure! 'aborts on bufdelete',      /.*/, :osx, backend: :vimproc

  # Git have different way to escape globs:
  #   `ag *.txt`,  `ag \*.txt` - wildcard ad regular strings
  #   `git grep *.txt`, `git grep \*.txt` - both wildcards
  pending! 'globbing escaped *', /expected to have results.*got.*\[.+\]/m, adapter: :git
end
