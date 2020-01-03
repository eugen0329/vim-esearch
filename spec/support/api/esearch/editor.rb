# frozen_string_literal: true

require 'yaml'
require 'active_support/core_ext/class/attribute'

# rubocop:disable Layout/ClassLength
class API::ESearch::Editor
  include API::Mixins::Throttling

  KEEP_VERTICAL_POSITION = KEEP_HORIZONTAL_POSITION = 0

  class_attribute :cache_enabled, default: true
  class_attribute :throttle_interval, default: Configuration.editor_throttle_interval

  attr_reader :cache, :vim_client_getter

  def initialize(vim_client_getter)
    @vim_client_getter = vim_client_getter
    @cache = CacheStore.new
  end

  def line(number)
    echo("getline(#{number})")
  end

  def lines(from: 1)
    return enum_for(:lines, from: from) { echo("line('$')").to_i } unless block_given?

    from.upto(lines.size).each do |line_number|
      yield(line(line_number))
    end
  end

  def cd!(where)
    press! ":cd #{where}<Enter>"
  end

  def bufname(arg)
    echo("bufname('#{arg}')")
  end

  def echo(arg)
    cached(:echo, arg) do
      vim.echo(arg)
    end
  end

  def current_buffer_name
    bufname('%')
  end

  def current_line_number
    current_cursor_location[0]
  end

  def current_column_number
    current_cursor_location[1]
  end

  def current_cursor_location
    cached(:current_cursor_location) do
      YAML.safe_load(echo("[line('.'),col('.')]"))
    end
  end

  def locate_cursor!(line_number, column_number)
    command!("call cursor(#{line_number},#{column_number})").to_i == 0
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

  def quickfix_window_name_with_filetype
    cached(:quickfix_window_name_with_filetype) do
      YAML.safe_load(echo("[get(w:, 'quickfix_title', ''), &ft]"))
    end
  end

  def quickfix_window_name
    echo("get(w:, 'quickfix_title', '')")
  end

  def with_ignore_cache
    @with_ignore_cache = true
    yield
  ensure
    @with_ignore_cache = false
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

  private

  def vim
    vim_client_getter.call
  end

  def cached(name, *args)
    return yield if @with_ignore_cache || !cache_enabled?

    cache.fetch([name, *args]) { yield }
  end

  def clear_cache
    return if @with_ignore_cache || !cache_enabled?

    cache.clear
  end
end
# rubocop:enable Layout/ClassLength
