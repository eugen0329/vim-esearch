# frozen_string_literal: true

module API::Mixins::RollbackState
  class RollbackCursorPositionError < RuntimeError; end

  class RollbackCurrentBufferError < RuntimeError; end

  def rollback_cursor_location(editor, &block)
    rollback_cursor_location_inside_buffer(editor) do
      rollback_current_buffer(editor, &block)
    end
  end

  def rollback_current_buffer(editor)
    old_buffer_name = editor.current_buffer_name

    yield
  ensure
    10.times do
      break if old_buffer_name == editor.current_buffer_name

      editor.press! '<c-o>'
    end

    if old_buffer_name != editor.current_buffer_name
      raise RollbackCurrentBufferError,
        "can't rollback to buffer #{old_buffer_name.inspect} #{editor.current_buffer_name.inspect}"
    end
  end

  def rollback_cursor_location_inside_buffer(editor)
    old_line_number = editor.current_line_number
    old_column_number = editor.current_column_number

    yield
  ensure
    editor.locate_cursor!(old_line_number, old_column_number)
    if old_line_number != editor.current_line_number
      raise RollbackCursorPositionError, "can't rollback to line #{old_line_number}"
    end
    if old_column_number != editor.current_column_number
      raise RollbackCursorPositionError, "can't rollback to column #{old_column_number}"
    end
  end
end
