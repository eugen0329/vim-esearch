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
  # TODO: investigate
  skip! '/3\d+5/', adapter: :git, matching: :regexp
  skip! '/3\d*5/', adapter: :git, matching: :regexp
  skip! '/3\d+5/', adapter: :grep, matching: :regexp
  skip! '/3\d*5/', adapter: :grep, matching: :regexp

  # Git have different way to escape globs:
  #   `ag *.txt`,       `ag \*.txt`       - a wildcard and a regular string
  #   `git grep *.txt`, `git grep \*.txt` - both metachars
  pending! 'globbing escaped *', /expected to have results.*got.*\[.+\]/m, adapter: :git

  # Ack cannot work with files named ~
  pending! 'searching in a file with name "~"', /MissingEntry/, adapter: :ack
  pending! 'searching in a file with name "-"', /MissingEntry/, adapter: :ack
end
