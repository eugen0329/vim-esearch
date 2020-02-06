# frozen_string_literal: true

RSpec.shared_context 'setup syntax testing' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext

  let!(:test_directory) { directory([source_file], 'window/syntax/').persist! }

  before do
    esearch.configure!(regex: 1, backend: 'system', adapter: 'ag', 'out': 'win')
    esearch.search! '^', paths: [source_file.path.to_s]
    expect(esearch).to have_search_finished
  end

  it 'keeps lines highligh untouched' do
    expect(source_file.content).to have_line_numbers_highlight(%w[esearchLnum LineNr])
  end
end
