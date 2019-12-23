# frozen_string_literal: true

module API
  module Esearch
    class Window
      class Entry
        class OpenEntryError < RuntimeError; end

        attr_reader :editor, :context, :line_in_window, :relative_path

        def initialize(editor, relative_path, context, line_in_window)
          @editor = editor
          @relative_path = relative_path
          @context = context
          @line_in_window = line_in_window
        end

        def line_number
          context.to_i # takes leading int
        end

        def open
          old_buffer_name = editor.current_buffer_name
          editor.locate_line! line_in_window + 1
          editor.press_with_user_mappings! '\<Enter>'

          yield
        ensure
          editor.press! '<C-o>'
          if old_buffer_name != editor.current_buffer_name
            raise OpenEntryError, "haven't managed to return back"
          end
        end
      end
    end
  end
end
