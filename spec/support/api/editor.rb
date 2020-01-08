# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'

# rubocop:disable Layout/ClassLength
class API::Editor
  include API::Mixins::Throttling
  include TaggedLogging

  ReadProxy = Struct.new(:editor) do
    delegate :current_line_number,
      :current_column_number,
      :filetype,
      :quickfix_window_name,
      :current_buffer_name,
      :line,
      to: :editor
  end

  KEEP_VERTICAL_POSITION = KEEP_HORIZONTAL_POSITION = 0

  class_attribute :cache_enabled, default: true
  class_attribute :throttle_interval, default: Configuration.editor_throttle_interval
  attr_reader :vim_client_getter

  delegate :with_ignore_cache, :clear_cache, :var, :func, :echo, to: :reader

  def initialize(vim_client_getter)
    @vim_client_getter = vim_client_getter
  end

  def line(number)
    echo(func("getline(#{number})"))
  end

  def lines(from: 1)
    return enum_for(:lines, from: from) { echo(func("line('$')")) } unless block_given?

    from.upto(lines.size).each do |line_number|
      yield(echo { |e| e.line(line_number) })
    end
  end

  def cd!(where)
    press! ":cd #{where}<Enter>"
  end

  def bufname(arg)
    echo(func("bufname('#{arg}')"))
  end

  def current_buffer_name
    bufname('%')
  end

  def current_line_number
    echo(func("line('.')"))
  end

  def current_column_number
    echo(func("col('.')"))
  end

  def locate_cursor!(line_number, column_number)
    command!("call cursor(#{line_number},#{column_number})").to_i == 0
  end

  def edit!(filename)
    command!("edit #{filename}")
  end

  def pwd
    command('pwd')
  end

  def close!
    command!('close!')
  end

  # TODO: better name
  def ls(include_unlisted: true)
    return command('ls!') if include_unlisted

    command('ls')
  end

  def delete_all_buffers_and_clear_messages!
    command!('%bwipeout! | messages clear')
    # command!('%close')
  end
  alias cleanup! delete_all_buffers_and_clear_messages!

  def bufdelete!(ignore_unsaved_changes: false)
    return command!('bdelete!') if ignore_unsaved_changes

    command!('bdelete')
  end
  alias delete_current_buffer! bufdelete!

  def locate_line!(line_number)
    locate_cursor! line_number, KEEP_HORIZONTAL_POSITION
  end

  def locate_column!(column_number)
    locate_cursor! KEEP_VERTICAL_POSITION, column_number
  end

  def filetype
    echo(var('&ft'))
  end

  def quickfix_window_name
    echo(func("get(w:, 'quickfix_title', '')"))
  end

  def trigger_cursor_moved_event!
    press!('<Esc>lh')
  end

  def command(string_to_execute)
    vim.command(string_to_execute)
  end

  def command!(string_to_execute)
    clear_cache
    throttle(:state_modifying_interactions, interval: throttle_interval) do
      command(string_to_execute)
    end
  end

  def press!(keyboard_keys)
    clear_cache
    throttle(:state_modifying_interactions, interval: throttle_interval) do
      vim.normal(keyboard_keys)
    end
  end

  def press_with_user_mappings!(keyboard_keys)
    clear_cache
    throttle(:state_modifying_interactions, interval: throttle_interval) do
      vim.feedkeys keyboard_keys
    end
  end

  def raw_echo(arg)
    vim.echo(arg)
  end

  private

  def reader
    @reader ||= API::Editor::Read::Batch
                      .new(ReadProxy.new(self), vim_client_getter, cache_enabled)
  end

  def vim
    vim_client_getter.call
  end
end
# rubocop:enable Layout/ClassLength
