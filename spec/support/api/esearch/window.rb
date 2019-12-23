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
          editor.line(1) =~ /Finished/
        end
      end

      def has_output_1_result_in_header?
        editor.line(1) =~ /Matches in 1 lines, 1 file/
      end

      private

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
