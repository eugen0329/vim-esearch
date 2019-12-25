# frozen_string_literal: true

# require 'active_support/cache/memory_store'
# @cache = ActiveSupport::Cache::MemoryStore.new
require 'json'

class API::ESearch::Editor
  KEEP_VERTICAL_POSITION = KEEP_HORIZONTAL_POSITION = 0

  class_attribute :cache_enabled, default: true

  attr_reader :spec, :cache

  def initialize(spec)
    @spec = spec
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
    invalidate_cache
    spec.vim.normal(keys)
  end

  def bufname(arg)
    echo("bufname('#{arg}')")
  end

  def echo(arg)
    cached(:echo, arg) do
      spec.vim.echo(arg)
    end
  end

  def press_with_user_mappings!(what)
    invalidate_cache
    spec.vim.feedkeys what
  end

  def command!(string_to_execute)
    # TODO remove
    invalidate_cache
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

  # def current_line_number
  #   echo("line('.')").to_i
  # end
  # def current_column_number
  #   echo("col('.')").to_i
  # end

  def current_cursor_location
    cached(:current_cursor_location) do
      JSON.parse(echo("[line('.'),col('.')]"))
    end
  end

  def locate_cursor!(line_number, column_number)
    invalidate_cache
    spec.vim.command("call cursor(#{line_number},#{column_number})").to_i == 0
  end

  def close!
    invalidate_cache
    command('close!')
  end

  def bdelete!
    command!('bdelete')
  end

  def locate_line!(line_number)
    invalidate_cache
    locate_cursor! line_number, KEEP_HORIZONTAL_POSITION
  end

  def locate_column!(column_number)
    invalidate_cache
    locate_cursor! KEEP_VERTICAL_POSITION, column_number
  end

  def disable_cache
    @disable_cache = true
    yield
  ensure
    @disable_cache = false
  end

  private

  def command(string_to_execute)
    spec.vim.command(string_to_execute)
  end

  def cached(name, *args)
    return yield if @disable_cache || !cache_enabled?

    cache.fetch([name, *args]) { yield }
  end

  def invalidate_cache
    return if @disable_cache || !cache_enabled?
    cache.clear
  end
end
