# frozen_string_literal: true

module API
  module Esearch
    class Editor
      attr_reader :spec

      DONT_MOVE_CURSOR = 0

      def initialize(spec)
        @spec = spec
      end

      def line(number)
        spec.vim.echo("getline(#{number})")
      end

      def lines
        return enum_for(:lines) { spec.vim.echo("line('$')").to_i } unless block_given?

        1.upto(lines.size).each do |line_number|
          yield(line(line_number))
        end
      end

      def cd!(where)
        spec.press ":cd #{where}<Enter>"
      end

      def press!(what)
        spec.press what
      end

      def bufname(arg)
        spec.bufname arg
      end
    end
  end
end
