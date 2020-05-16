# frozen_string_literal: true

RSpec.shared_context 'setup syntax testing' do
  include Helpers::FileSystem
  include Helpers::WindowSyntaxContext
  include Helpers::ReportEditorStateOnError

  let!(:test_directory) { directory([source_file], 'window/syntax/').persist! }

  include_context 'report editor state on error'

  before do
    esearch.configure!(regex: 1, backend: 'system', adapter: 'ag', 'out': 'win', root_markers: [])
    esearch.search! '^', paths: source_file.path.to_s
    expect(esearch).to have_search_finished
  end
  after do
    expect(editor.messages).not_to include('Error')
    expect(editor.messages).not_to match(/E\d{1,4}:/)
    expect(editor.messages.size).to be < 2
    editor.cleanup!
  end

  it 'keeps line numbers highlight untouched' do
    expect(source_file.content).to have_line_numbers_highlight(%w[esearchLineNr LineNr])
  end

  it 'keeps header highlight untouched' do
    is_expected.to have_highlight_aliases(
      '\%1l[0-9]*'  => %w[esearchStatistics Number]
    )
  end
end
