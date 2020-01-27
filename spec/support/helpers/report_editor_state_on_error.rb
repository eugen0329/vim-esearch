# frozen_string_literal: true

module Helpers::ReportEditorStateOnError
  extend RSpec::Matchers::DSL

  shared_context 'report editor state on error' do
    prepend_after do |e|
      next if e.exception.nil?

      # TODO: figure out how trigger formatter before Editor#cleanup! to capture
      # all the data
      DumpEditorStateOnErrorFormatter
        .new($stderr)
        .example_failed(nil)
    end
  end
end
