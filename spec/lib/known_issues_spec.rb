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
      klass.random_issues = []
    end
  end

  define_negated_matcher :not_be_skipped, :be_skipped
  define_negated_matcher :not_be_pending, :be_pending

  describe '#skip!' do
    before do
      known_issues.allow_tests_to_fail_matching_by_metadata do
        skip! 'skippable description', :skippable_tag
      end
    end

    it 'skips matching only full metadata' do
      executed = []
      group = RSpec.describe do
        example('example with skippable description', :skippable_tag) {  }
        example('another description', :another_tag) {  }
        example('example with skippable description', :another_tag) {  }
        example('another description', :skippable_tag) {  }
      end.tap(&:run)

      expect(group.examples.first).to be_skipped
      expect(group.examples[1..]).to all not_be_pending.and(not_be_skipped)
    end
  end

  describe '#random!' do
    before do
      known_issues.allow_tests_to_fail_matching_by_metadata do
        random! 'skippable description', /skippable exception/, :skippable_tag
      end
    end

    context 'when metadata matches' do
      context 'when exception matches' do
        it do
          group = RSpec.describe do
            example('skippable description', :skippable_tag) do
              raise 'skippable exception'
            end
          end.tap(&:run)

          expect(group.examples).to all be_skipped
        end
      end

      context "when exception doesn't matches" do
        it do
          group = RSpec.describe do
            example('skippable description', :skippable_tag) do
              raise 'another_exception'
            end
          end.tap(&:run)

          expect(group.examples)
            .to all not_be_pending
            .and not_be_skipped
          expect(group.examples.map(&:exception)).to all be_present
        end
      end

      context "when exceptions isn't raised" do
        it do
          group = RSpec.describe do
            example('skippable description', :skippable_tag) {}
          end.tap(&:run)

          expect(group.examples).to all be_skipped
        end
      end
    end

    context "when metadata doesn't match" do
      it do
        group = RSpec.describe do
          example('another description', :skippable_tag) do
            raise 'skippable exception'
          end
          example('skippable description', :another_tag) do
            raise 'skippable exception'
          end
          example('another exception', :another_tag) do
            raise 'skippable exception'
          end
        end.tap(&:run)

        expect(group.examples).to all not_be_pending.and(not_be_skipped)
        expect(group.examples.map(&:exception)).to all be_present
      end
    end
  end
end
