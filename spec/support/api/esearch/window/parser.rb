# frozen_string_literal: true

require 'ostruct'

module API
  module Esearch
    class Window
      class Parser
        attr_reader :spec, :editor

        def initialize(spec, editor)
          @spec = spec
          @editor = editor
        end

        def header_errors?
          header_parser.errors?
        end

        def header_finished?
          header_parser.finished?
        end

        def header
          header_parser.parse
        end

        def entries
          entries_parser.parse
        end

        def header_parser
          @header_parser ||= HeaderParser.new(spec, editor)
        end

        def entries_parser
          @entries_parser ||= EntriesParser.new(spec, editor)
        end
      end
    end
  end
end
