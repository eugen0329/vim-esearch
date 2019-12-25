# frozen_string_literal: true

module API::Mixins::RollbackCursorPosition
  class RollbackCursorPositionError < RuntimeError; end
  def rollback_cursor_position(editor, exception = RollbackCursorPositionError)
    old_buffer_name   = editor.current_buffer_name
    old_line_number   = editor.current_line_number
    old_column_number = editor.current_column_number

    yield
  ensure
    42.times do
      break if old_buffer_name == editor.current_buffer_name

      editor.press! '<C-o>'
    end
    raise exception, "can't locate buffer" if old_buffer_name != editor.current_buffer_name

    editor.locate_cursor!(old_line_number, old_column_number)
    raise exception, "can't locate line"    if old_line_number   != editor.current_line_number
    raise exception, "can't locate column " if old_column_number != editor.current_column_number
  end
end
