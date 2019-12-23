# frozen_string_literal: true

module API
  module Esearch
    class Window
      attr_reader :spec

      def initialize(spec)
        @spec = spec
      end

      def has_search_started?(timeout: 3.seconds)
        become_truthy_within(timeout) do
          spec.press('lh') # press jk to close "Press ENTER or type command to continue" prompt
          spec.bufname('%') =~ /Search/
        end
      end

      def has_search_finished?(timeout: 3.seconds)
        become_truthy_within(timeout) do
          spec.press('lh') # press jk to close "Press ENTER or type command to continue" prompt
          spec.line(1) =~ /Finished/
        end
      end

      def has_output_1_result?
        spec.line(1) =~ /Matches in 1 lines, 1 file/
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
