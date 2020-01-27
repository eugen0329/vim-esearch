# frozen_string_literal: true

require 'spec_helper'

describe KnownIssues do
  around do |e|
    require 'rspec/core/sandbox'
    RSpec::Core::Sandbox.sandboxed do |config|
      config.before(:context) { RSpec.current_example = nil }
      e.run
    end
  end

  let(:known_issues) do
    described_class.dup.tap do |klass|
      klass.skip_issues = []
      klass.pending_issues = []
    end
  end

  describe '#skip!' do
    it 'skips matching only full metadata' do
      executed = []

      known_issues.allow_tests_to_fail_matching_by_metadata do
        skip! 'description_to_skip', :tag_to_skip
      end

      RSpec.describe do
        it('example with description_to_skip', :tag_to_skip) do
          executed << :full_metadata_matches
        end
        it('nonimatching description',  :non_matching_tag) do
          executed << :no_matches_for_both_name_and_description
        end
        it('description_to_skip', :non_matching_tag) do
          executed << :only_description_matches
        end
        it('nonimatching description', :tag_to_skip)  do
          executed << :only_tag_matches
        end
      end.run

      expect(executed).to match_array(%i[
                             no_matches_for_both_name_and_description
                             only_description_matches
                             only_tag_matches
                             ])
    end
  end
end
