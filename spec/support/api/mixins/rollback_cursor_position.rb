# frozen_string_literal: true

module API::Mixins::RollbackCursorPosition
  class RollbackCursorPositionError < RuntimeError; end

  def rollback_cursor_position(editor, rollback_cursor = false, exception: RollbackCursorPositionError)
    old_buffer_name = editor.current_buffer_name

    if rollback_cursor
      old_line_number   = editor.current_line_number
      old_column_number = editor.current_column_number
    end

    yield
  ensure
    42.times do |_i|
      break if old_buffer_name == editor.current_buffer_name

      editor.press! '<C-o>'
    end
    raise exception, "can't rollback to buffer" if old_buffer_name != editor.current_buffer_name

    if rollback_cursor
      editor.locate_cursor!(old_line_number, old_column_number)
      raise exception, "can't rollback to line"    if old_line_number   != editor.current_line_number
      raise exception, "can't rollback to column " if old_column_number != editor.current_column_number
    end
  end
end
