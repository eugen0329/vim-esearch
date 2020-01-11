# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'
require 'active_support/notifications'

# rubocop:disable Layout/ClassLength
class API::Editor
  include API::Mixins::Throttling
  include TaggedLogging

  ReadProxy = Struct.new(:editor) do
    delegate :echo,
      :var,
      :func,
      :current_line_number,
      :current_column_number,
      :filetype,
      :quickfix_window_name,
      :current_buffer_name,
      :line,
      :lines_count,
      to: :editor
  end

  KEEP_VERTICAL_POSITION = KEEP_HORIZONTAL_POSITION = 0

  class_attribute :cache_enabled, default: true
  class_attribute :throttle_interval, default: Configuration.editor_throttle_interval
  attr_reader :vim_client_getter

  delegate :with_ignore_cache, :clear_cache, :var, :func, to: :reading

  def initialize(vim_client_getter)
    @vim_client_getter = vim_client_getter
  end

  def line(number)
    echo(func("getline(#{number})"))
  end

  def lines_iterator(from:)
    first_line_from_range = line(from)
    size = lines_count
    return if size < from

    yield first_line_from_range

    (from + 1).upto(size).each do |line_number|
      yield(line(line_number))
    end
  end

  def lines_all(from:)
    lns = echo(func("getline(#{from},line('$'))"))
    lns.each { |l| yield l }
  end

  def lines(from: 1, &block)
    return enum_for(:lines, from: from) { lines_count } unless block_given?

    lines_all(from: from, &block)
    # lines_iterator(from: from, &block)
  end

  def lines_count
    echo(func("line('$')"))
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

  def cleanup!
    delete_all_buffers_and_clear_messages!
    clear_cache
  end
  # alias cleanup! delete_all_buffers_and_clear_messages!

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
    # instrument(:command, data: string_to_execute) do
    vim.command(string_to_execute)
    # end
  end

  def command!(string_to_execute)
    clear_cache

    instrument(:command!, data: string_to_execute) do
      throttle(:state_modifying_interactions, interval: throttle_interval) do
        command(string_to_execute)
      end
    end
  end

  def press!(keyboard_keys)
    clear_cache

    instrument(:press, data: keyboard_keys) do
      throttle(:state_modifying_interactions, interval: throttle_interval) do
        vim.normal(keyboard_keys)
      end
    end
  end

  def press_with_user_mappings!(keyboard_keys)
    clear_cache

    instrument(:press_with_user_mappings!, data: keyboard_keys) do
      throttle(:state_modifying_interactions, interval: throttle_interval) do
        vim.feedkeys keyboard_keys
      end
    end
  end

  def raw_echo(arg)
    vim.echo(arg)
  end

  def reading
    @reading ||= API::Editor::Read::Batched
                 .new(self, vim_client_getter, cache_enabled)
  end

  def echo(arg)
    reading.echo(arg)
  end

  delegate :serialize,   to: :serializer
  delegate :deserialize, to: :deserializer
  def serializer
    @serializer ||= API::Editor::Serialization::Serializer.new
  end

  def deserializer
    @deserializer ||= API::Editor::Serialization::Deserializer.new
  end

  def normalize_range(range)
    from = [range.begin, 1].compact.max
    to = [range.end, Float::INFINITY].compact.min
    raise ArgumentError if from > to

    [from, to]
  end

  private

  def instrument(operation, options = {})
    options.merge!(operation: operation)
    ActiveSupport::Notifications.instrument("editor.#{operation}", options) { yield }
  end

  def vim
    vim_client_getter.call
  end
end
# rubocop:enable Layout/ClassLength
