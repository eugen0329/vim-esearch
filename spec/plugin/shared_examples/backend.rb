# frozen_string_literal: true

# TODO: completely rewrite
RSpec.shared_examples 'a backend' do |backend|
  SEARCH_UTIL_ADAPTERS.each do |adapter|
    context "with #{adapter} adapter" do
      around do |example|
        esearch_settings(backend: backend, adapter: adapter, out: 'win')
        example.run
        cmd('close!') if bufname('%') =~ /Search/
      end

      context 'matching modes' do
        before { press ":cd #{working_directory}/spec/fixtures/backend/<Enter>" }

        context('literal') { settings_dependent_context('literal', regex: 0) }
        context('regex')   { settings_dependent_context('regex', regex: 1) }
      end

      context 'with relative path' do
        let(:context_fixtures_path) { "#{working_directory}/spec/fixtures/relative_paths" }
        let(:expected_file_content) { 'content_of_file_inside' }
        let(:directory) { 'directory' }
        let(:expected_filename) { 'file_inside_directory.txt' }
        let(:test_query) { 'content' }

        before do
          esearch_settings(regex: 0)
          cmd "cd #{context_fixtures_path}"
        end

        it 'provides correct path when searching outside the cwd' do
          press ":call esearch#init({'cwd': '#{context_fixtures_path}/#{directory}'})<Enter>#{test_query}<Enter>"

          # TODO: reduce duplication
          expect {
            press('j') # press j to close "Press ENTER or type command to continue" prompt
            bufname('%') =~ /Search/
          }.to become_true_within(5.second)
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

def settings_dependent_context(matching_type, settings)
  before do
    press ":cd #{working_directory}/spec/fixtures/backend/<Enter>"
    esearch_settings(settings)
  end
  after { cmd('bdelete') if bufname('%') =~ /Search/ }

  File.readlines("spec/fixtures/backend/#{matching_type}.txt").map(&:chomp).each do |test_query|
    it "finds `#{test_query}`" do
      press ":call esearch#init()<Enter>#{test_query}<Enter>"
      wait_for_search_start

      expect {
        press 'lh'
        line(1) =~ /Finish/i
      }.to become_true_within(10.seconds),
        -> { "Expected first line to match /Finish/, got `#{line(1)}`" }
    end
  end
end
