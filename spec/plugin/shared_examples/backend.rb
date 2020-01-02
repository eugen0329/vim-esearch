# frozen_string_literal: true

# TODO: completely rewrite
RSpec.shared_examples 'a backend' do |backend|
  %w[ack ag git grep pt rg].each do |adapter|
    context "with #{adapter} adapter" do
      around do |example|
        esearch.configure!(backend: backend, adapter: adapter, out: 'win')
        example.run
        cmd('close!') if bufname('%') =~ /Search/
      end

      context 'with relative path' do
        let(:context_fixtures_path) { "#{Configuration.root}/spec/fixtures/relative_paths" }
        let(:expected_file_content) { 'content_of_file_inside' }
        let(:directory) { 'directory' }
        let(:expected_filename) { 'file_inside_directory.txt' }
        let(:test_query) { 'content' }

        before do
          esearch.configure!(regex: 0)

          esearch.configuration.adapter_bin = Configuration.pt_path if adapter == 'pt'
          esearch.configuration.adapter_bin = Configuration.rg_path if adapter == 'rg'

          cmd "cd #{context_fixtures_path}"
        end
        after { esearch.cleanup! }

        it 'provides correct path when searching outside the cwd' do
          press ":call esearch#init({'cwd': '#{context_fixtures_path}/#{directory}'})<Enter>#{test_query}<Enter>"

          # TODO: reduce duplication
          expect {
            press('j') # press j to close "Press ENTER or type command to continue" prompt
            bufname('%') =~ /Search/
          }.to become_true_within(5.second)

          expect(esearch).to have_not_reported_errors
          expect { line(1) == 'Matches in 1 lines, 1 file(s). Finished.' }.to become_true_within(10.seconds),
            -> { "Expected first line to match /Finish/, got `#{line(1)}`" }

          expect(buffer_content)
            .to include(expected_file_content)
            .and include(expected_filename)
            .and not_include('content_of_file_outside')

          press_with_respecting_mappings '\<Enter>'
          expect(line(1))
            .to include(expected_file_content)
            .and not_include('content_of_file_outside')

          expect(bufname('%')).to end_with([directory, expected_filename].join('/'))
        end
      end
    end
  end

  include_context 'dumpable'
end
