# frozen_string_literal: true

module API
  module ESearch
    class Window
      class Entry
        include API::Mixins::RollbackCursorPosition

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

          rollback_cursor_position(editor) do
            editor.locate_line! line_in_window + 1
            editor.press_with_user_mappings! '\<Enter>'

            raise OpenEntryError, "can't open entry #{inspect}" if old_buffer_name == editor.current_buffer_name

            yield
          end
        end
      end
    end
  end
end
