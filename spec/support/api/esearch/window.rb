# frozen_string_literal: true

module API
  module Esearch
    class Window
      attr_reader :spec, :editor

      def initialize(spec, editor)
        @spec = spec
        @editor = editor
      end

      def has_search_started?(timeout: 3.seconds)
        become_truthy_within(timeout) do
          editor.press!('lh') # press jk to close "Press ENTER or type command to continue" prompt
          editor.bufname('%') =~ /Search/
        end
      end

      def has_search_finished?(timeout: 3.seconds)
        become_truthy_within(timeout) do
          editor.press!('lh') # press jk to close "Press ENTER or type command to continue" prompt
          parser.header_finished?
        end
      end

      def has_reported_single_result_in_header?
        parser.header.tap { |h| return h.lines_count == 1 && h.files_count == 1 }
      end

      def has_outputted_result_in_file?(relative_path, line, column = nil)
        parser.entries.any? do |entry|
          next if entry.relative_path != relative_path
          next if entry.line_number != line

          entry.open do
            editor.current_line_number == line &&
              (!column || editor.current_column_number == column)
          end
        end
      end

      private

      def parser
        @parser ||= Parser.new(spec, editor)
      end

      def become_truthy_within(timeout)
        Timeout.timeout(timeout, Timeout::Error) do
          loop do
            return true if yield

            sleep 0.1
          end
        end
      rescue Timeout::Error
        false
      end
    end
  end
end
