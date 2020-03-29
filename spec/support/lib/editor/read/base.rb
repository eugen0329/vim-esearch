# frozen_string_literal: true

class Editor::Read::Base
  include VimlValue::SerializationHelpers

  VIM_EXCEPTION_REGEXP = /\AVim(\(\w+\))?:E\d+:/.freeze
  VIMRUNNER_EXCEPTION_REGEXP = /\AVimrunner(\(\w+\))?/.freeze

  class ReadError < RuntimeError; end

  attr_reader :vim_client_getter, :cache_enabled

  def initialize(vim_client_getter, cache_enabled)
    @vim_client_getter = vim_client_getter
    @cache_enabled = cache_enabled
    @cache = CacheStore.new
  end

  def echo
    raise NotImplementedError
  end

  # TODO
  def echo_command(command)
    vim.command(command)
  end

  def invalidate_cache!
    cache.clear
  end

  def evaluated?(_value)
    true
  end

  def with_ignore_cache
    @with_ignore_cache ||= []
    @with_ignore_cache << true
    yield
  ensure
    @with_ignore_cache.pop
  end

  private

  def reset!
    cache.clear
  end

  def cache
    return null_cache if @with_ignore_cache&.last || !cache_enabled

    @cache
  end

  def evaluate(str)
    result = vim.echo(str)
    if VIM_EXCEPTION_REGEXP.match?(result) ||
       VIMRUNNER_EXCEPTION_REGEXP.match?(result)
      reset!
      raise ReadError, result
    end

    result
  end

  def null_cache
    @null_cache ||= ActiveSupport::Cache::NullStore.new
  end

  def vim
    vim_client_getter.call
  end
end
