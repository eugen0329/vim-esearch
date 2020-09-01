# frozen_string_literal: true

require 'spec_helper'
require 'plugin/shared_examples/backend'
require 'plugin/shared_examples/abortable_backend'

describe 'esearch#backend', :backend do
  include Helpers::FileSystem
  include Helpers::Strings
  include Helpers::Output
  include Helpers::ReportEditorStateOnError
  include VimlValue::SerializationHelpers

  define_negated_matcher :not_to_change, :change

  let(:live_update_debounce_wait) { 50 }
  before do
    esearch.configure(
      root_markers:              [],
      live_update_debounce_wait: live_update_debounce_wait
    )
  end

  context 'when searching in a file with name' do
    let(:search_string) { 'a' } # the search_string is secondary for the examples group
    let(:line) { 2 }
    let(:column) { 3..4 }
    let(:files) { [file("_\n__#{search_string}1_")] }
    let(:test_directory) { directory(files).persist! }

    before do
      esearch.configuration.submit!
      esearch.cd! test_directory
    end
    append_after { esearch.cleanup! }

    include_context 'report editor state on error'

    describe 'default .win_new' do
      context 'when the same patterns are searched' do
        it 'reuses buffers' do
          2.times do
            esearch.input!(search_string)
            expect(esearch)
              .to  have_live_update_search_started
              .and have_search_finished
              .and have_not_reported_errors

            editor.send_keys :enter
            expect(esearch)
              .to  have_search_finished
              .and have_not_reported_errors
              .and have_valid_buffer_basename(search_string)
          end
          expect(editor.buffers.count).to eq(1)
        end
      end

      context 'when a pattern is submitted after the update' do
        it "doesn't restart the search" do
          esearch.input!(search_string)
          expect(esearch)
            .to  have_live_update_search_started
            .and have_search_finished
            .and have_not_reported_errors

          expect do
            editor.send_keys :enter
            expect(esearch)
              .to  have_search_finished
              .and have_not_reported_errors
              .and have_valid_buffer_basename(search_string)
          end.not_to change { editor.echo var('b:esearch.id') }
        end
      end

      context 'when a pattern is submitted before the first update' do
        let(:live_update_debounce_wait) { 42_000_000 }

        it 'outputs the search results' do
          esearch.input!(search_string)
          expect(esearch).to have_no_live_update_search_started(timeout: 0.5.seconds)

          editor.send_keys :enter
          expect(esearch)
            .to  have_search_finished
            .and have_not_reported_errors
            .and have_valid_buffer_basename(search_string)
        end
      end

      context 'when the search is reloaded' do
        it 'stays in the windwo' do
          esearch.search!(search_string)
          expect do
            editor.send_keys 'R'
          end.to change { editor.echo var('b:esearch.id') }
            .and not_to_change { editor.tabs }
        end
      end

      context 'when a pattern is submitted before the second update' do
        let(:live_update_debounce_wait) { 1000 }

        it 'outputs the search results' do
          esearch.input!(search_string)
          expect(esearch)
            .to  have_live_update_search_started(timeout: 2.seconds)
            .and have_search_finished
            .and have_not_reported_errors

          expect do
            editor.send_keys '42'
            editor.send_keys :enter
            expect(esearch)
              .to  have_search_finished
              .and have_not_reported_errors
              .and have_valid_buffer_basename("#{search_string}42")
          end.to change { editor.echo var('b:esearch.id') }
        end
      end
    end
  end
end
