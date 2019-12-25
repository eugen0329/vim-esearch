# frozen_string_literal: true

module API
  module ESearch
    class Window
      class EntriesParser
        class MissingEntryError < RuntimeError; end

        FILE_NAME_REGEXP = /\A[^ ]/.freeze
        FILE_ENTRY_REGEXP = /\A\s+\d+/.freeze

        attr_reader :spec, :editor, :lines_iterator

        def initialize(spec, editor)
          @spec = spec
          @editor = editor
          @lines_iterator = editor.lines.with_index
        end

        def parse
          return enum_for(:parse) { 0 if editor.lines.size < 3 } unless block_given?
          return if parse.size == 1

          lines_iterator.rewind
          begin
            fast_forward_header!

            loop do
              relative_path = next_file_relative_path!
              raise MissingEntryError unless line_with_entry?

              next_lines_with_entries! { |line| yield Entry.new(editor, relative_path, *line) }
            end
          rescue StopIteration
            nil
          end
        end

        private

        def line_with_entry?
          lines_iterator.peek[0] =~ FILE_ENTRY_REGEXP
        end

        def fast_forward_header!
          lines_iterator.next while lines_iterator.peek[0] =~ HeaderParser::HEADER_REGEXP
        end

        def next_file_relative_path!
          relative_path = lines_iterator.next[0] while relative_path !~ FILE_NAME_REGEXP
          relative_path
        end

        def next_lines_with_entries!
          yield lines_iterator.next while line_with_entry?
        end
      end
    end
  end
end
