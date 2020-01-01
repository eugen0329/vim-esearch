# frozen_string_literal: true

require 'yaml'
require 'active_support/core_ext/class/attribute'

# rubocop:disable Layout/ClassLength
class API::ESearch::Editor
  KEEP_VERTICAL_POSITION = KEEP_HORIZONTAL_POSITION = 0

  class_attribute :cache_enabled, default: true

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

  def press!(keys)
    clear_cache
    vim.normal(keys)
  end

  def bufname(arg)
    echo("bufname('#{arg}')")
  end

  def echo(arg)
    cached(:echo, arg) do
      vim.echo(arg)
    end
  end

  def press_with_user_mappings!(what)
    clear_cache
    vim.feedkeys what
  end

  def command!(string_to_execute)
    clear_cache
    command(string_to_execute)
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
    clear_cache
    vim.command("call cursor(#{line_number},#{column_number})").to_i == 0
  end

  def close!
    clear_cache
    command('close!')
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

  def delete_current_buffer!(ignore_unsaved_changes: false)
    return command!('bwipeout!') if ignore_unsaved_changes

    command!('bwipeout!')
  end
  alias bufdelete! delete_current_buffer!

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
    clear_cache
    press!('<Esc>lh')
  end

  private

  def vim
    vim_client_getter.call
  end

  def command(string_to_execute)
    vim.command(string_to_execute)
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
