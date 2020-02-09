# frozen_string_literal: true

# TODO: completely rewrite
RSpec.shared_examples 'a backend' do |backend|
  include Helpers::Output
  include Helpers::ReportEditorStateOnError

  %w[ack ag git grep pt rg].each do |adapter|
    context "with #{adapter} adapter", :relative_paths do
      around do |example|
        esearch.configure!(backend: backend, adapter: adapter, out: 'win')
        example.run
      end

      include_context 'report editor state on error'

      context 'with relative path' do
        let(:context_fixtures_path) { "#{Configuration.root}/spec/fixtures/relative_paths" }
        let(:expected_file_content) { 'content_of_file_inside' }
        let(:directory) { 'directory' }
        let(:expected_filename) { 'file_inside_directory.txt' }
        let(:test_query) { 'content' }
        let(:directory_path) { "#{context_fixtures_path}/#{directory}" }

        before do
          esearch.configure!(regex: 0)

          esearch.configuration.adapter_bin = Configuration.pt_path if adapter == 'pt'
          esearch.configuration.adapter_bin = Configuration.rg_path if adapter == 'rg'

          editor.cd! context_fixtures_path
        end
        after { esearch.cleanup! }

        it 'provides correct path when searching outside the cwd' do
          esearch.search! test_query, cwd: directory_path
          # TODO: reduce duplication
          expect(esearch).to have_search_started

          expect(esearch)
            .to  have_search_finished
            .and have_not_reported_errors

          expect(editor.lines.to_a.join("\n"))
            .to include(expected_file_content)
            .and include(expected_filename)
            .and not_include('content_of_file_outside')

          editor.press_with_user_mappings! '\<Enter>'
          expect(editor.lines.first)
            .to include(expected_file_content)
            .and not_include('content_of_file_outside')

          expect(editor.current_buffer_name)
            .to end_with([directory, expected_filename].join('/'))
        end
      end
    end
  end
end
