# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'
require 'active_support/notifications'

# rubocop:disable Layout/ClassLength
class API::Editor
  include API::Mixins::Throttling

  KEEP_VERTICAL_POSITION = KEEP_HORIZONTAL_POSITION = 0

  class_attribute :cache_enabled, default: true
  class_attribute :throttle_interval, default: Configuration.editor_throttle_interval
  attr_reader :vim_client_getter

  delegate :cached?, :evaluated?, :with_ignore_cache, :clear_cache, :var, :func, to: :reader
  # TODO
  delegate :serialize, to: :reader

  def initialize(vim_client_getter, cache_enabled: self.class.cache_enabled)
    @cache_enabled = cache_enabled
    @vim_client_getter = vim_client_getter
  end

  def line(number)
    echo func('getline', number)
  end

  def lines(range = nil, prefetch_count: 4)
    raise ArgumentError unless prefetch_count.positive?
    return enum_for(:lines, range, prefetch_count: prefetch_count) { lines_count } unless block_given?

    from, to = lines_range(range)
    current_lines_count = lines_count

    from.step(to, prefetch_count).each do |prefetch_from|
      break if evaluated?(current_lines_count) && current_lines_count < prefetch_from

      prefetch_to = [to || Float::INFINITY, prefetch_from + prefetch_count - 1].min
      lines_array(prefetch_from..prefetch_to)
        .each { |line_content| yield(line_content) }
    end
  end

  def lines_array(range = nil)
    from, to = lines_range(range)
    to = "line('$')" if to.nil?

    echo func('getline', from, to)
  end

  def lines_count
    echo func('line', '$')
  end

  def cd!(where)
    press! ":cd #{where}<Enter>"
  end

  def bufname(arg)
    echo func('bufname', arg)
  end

  def current_buffer_name
    bufname('%')
  end

  def current_line_number
    echo func('line', '.')
  end

  def current_column_number
    echo func('col', '.')
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
    echo var('&ft')
  end

  def quickfix_window_name
    echo func('get', var('w:'), 'quickfix_title', '')
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
    vim.echo arg
  end

  def reader
    @reader ||= API::Editor::Read::Batched
                .new(self, vim_client_getter, @cache_enabled)
  end

  def echo(arg)
    reader.echo arg
  end

  private

  def lines_range(range)
    return [1, nil] if range.blank?

    raise ArgumentError if range.begin.present? && range.begin < 1

    from = [range.begin, 1].compact.max
    to = range.end
    raise ArgumentError if to.present? && from > to

    [from, to]
  end

  def instrument(operation, options = {})
    options.merge!(operation: operation)
    ActiveSupport::Notifications.instrument("editor.#{operation}", options) { yield }
  end

  def vim
    vim_client_getter.call
  end
end
# rubocop:enable Layout/ClassLength
