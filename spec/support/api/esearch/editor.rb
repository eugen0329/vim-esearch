# frozen_string_literal: true

module API
  module ESearch
    class Editor
      attr_reader :spec

      KEEP_VERTICAL_POSITION = KEEP_HORIZONTAL_POSITION = 0

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

      def press_with_user_mappings!(what)
        spec.vim.feedkeys what
      end

      def command!(string_to_execute)
        spec.vim.command(string_to_execute)
      end

      def current_buffer_name
        bufname('%')
      end

      def current_line_number
        spec.vim.echo("line('.')").to_i
      end

      def current_column_number
        spec.vim.echo("col('.')").to_i
      end

      def locate_cursor!(line_number, column_number)
        spec.vim.command("call cursor(#{line_number},#{column_number})").to_i == 0
      end

      def locate_line!(line_number)
        locate_cursor! line_number, KEEP_HORIZONTAL_POSITION
      end

      def locate_column!(column_number)
        locate_cursor! KEEP_VERTICAL_POSITION, column_number
      end
    end
  end
end
