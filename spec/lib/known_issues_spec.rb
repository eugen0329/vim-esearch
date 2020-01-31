# frozen_string_literal: true

require 'spec_helper'

describe KnownIssues do
  around do |e|
    require 'rspec/core/sandbox'
    RSpec::Core::Sandbox.sandboxed do |_config|
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
  matcher :have_exception_present do
    match { |example| example.exception.present? }
  end

  describe '#skip!' do
    before do
      known_issues.allow_tests_to_fail_matching_by_metadata do
        skip! 'skippable description', :skippable_tag
      end
    end

    it 'skips by matching only full metadata' do
      group = RSpec.describe do
        example('example with skippable description', :skippable_tag) {}
        example('another description', :another_tag) {}
        example('example with skippable description', :another_tag) {}
        example('another description', :skippable_tag) {}
      end.tap(&:run)

      expect(group.examples.first).to be_skipped
      expect(group.examples[1..]).to all not_be_pending & not_be_skipped
    end
  end

  describe '#random_failure!' do
    before do
      known_issues.allow_tests_to_fail_matching_by_metadata do
        random_failure! 'skippable description', /skippable failure/, :skippable_tag
      end
    end

    context 'when metadata matches' do
      context 'when exception matches' do
        it 'marks an example with #skip call' do
          group = RSpec.describe do
            example('skippable description', :skippable_tag) do
              expect(1).to eq(2), 'skippable failure'
            end
          end.tap(&:run)

          expect(group.examples).to all be_skipped
        end
      end

      context "when exception doesn't match" do
        it "doesn't rescue the exception" do
          group = RSpec.describe do
            example('skippable description', :skippable_tag) do
              expect(2).to eq(4), 'another failure'
            end
          end.tap(&:run)

          expect(group.examples).to all not_be_pending & not_be_skipped
          expect(group.examples).to all have_exception_present
        end
      end

      context "when exceptions isn't raised" do
        it 'marks an example with #skip call' do
          group = RSpec.describe do
            example('skippable description', :skippable_tag) {}
          end.tap(&:run)

          expect(group.examples).to all be_skipped
        end
      end
    end

    context "when metadata doesn't match" do
      it "doesn't rescue the exception" do
        group = RSpec.describe do
          example('another description', :skippable_tag) do
            expect(1).to eq(2), 'skippable failure'
          end
          example('skippable description', :another_tag) do
            expect(1).to eq(2), 'skippable failure'
          end
          example('another failure', :another_tag) do
            expect(1).to eq(2), 'skippable failure'
          end
        end.tap(&:run)

        expect(group.examples).to all not_be_pending & not_be_skipped
        expect(group.examples).to all have_exception_present
      end
    end
  end

  describe '#pending!' do
    before do
      known_issues.allow_tests_to_fail_matching_by_metadata do
        pending! 'skippable description', /skippable failure/, :skippable_tag
      end
    end

    context 'when metadata matches' do
      context 'when exception matches' do
        it 'marks an example with #pending call' do
          known_issues_klass = known_issues
          group = RSpec.describe do
            example('skippable description', :skippable_tag) do
              known_issues_klass.mark_example_pending_if_known_issue(self) do
                expect(1).to eq(2), 'skippable failure'
              end
            end
          end.tap(&:run)

          expect(group.examples).to all be_pending & not_be_skipped
        end
      end

      context "when exception doesn't match" do
        it "doesn't rescue the exception" do
          group = RSpec.describe do
            example('skippable description', :skippable_tag) do
              known_issues_klass.mark_example_pending_if_known_issue(self) do
                expect(2).to eq(4), 'another failure'
              end
            end
          end.tap(&:run)

          expect(group.examples).to all not_be_pending & not_be_skipped
          expect(group.examples).to all have_exception_present
        end
      end

      context "when exceptions isn't raised" do
        it 'invokes pending and fails an example (as #pending normally do)' do
          group = RSpec.describe do
            example('skippable description', :skippable_tag) do
              known_issues_klass.mark_example_pending_if_known_issue(self) {}
            end
          end.tap(&:run)

          expect(group.examples).to all not_be_pending & not_be_skipped
          expect(group.examples).to all have_exception_present
        end
      end
    end

    context "when metadata doesn't match" do
      it "doesn't rescue the exception" do
        group = RSpec.describe do
          example('another description', :skippable_tag) do
            known_issues_klass.mark_example_pending_if_known_issue(self) do
              expect(1).to eq(2), 'skippable failure'
            end
          end
          example('skippable description', :another_tag) do
            known_issues_klass.mark_example_pending_if_known_issue(self) do
              expect(1).to eq(2), 'skippable failure'
            end
          end
          example('another failure', :another_tag) do
            known_issues_klass.mark_example_pending_if_known_issue(self) do
              expect(1).to eq(2), 'skippable failure'
            end
          end
        end.tap(&:run)

        expect(group.examples).to all not_be_pending & not_be_skipped
        expect(group.examples).to all have_exception_present
      end
    end
  end
end
