# frozen_string_literal: true

class Editor::Read::Base
  include VimlValue::SerializationHelpers

  VIM_EXCEPTION_REGEXP = /\AVim(\(echo\))?:E\d+:/.freeze
  NULL_CACHE = ::ActiveSupport::Cache::NullStore.new.freeze

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

  def handle_state_change!
    cache.clear
  end

  def evaluated?(_value)
    true
  end

  def with_ignore_cache
    @with_ignore_cache = true
    yield
  ensure
    @with_ignore_cache = false
  end

  private

  def cache
    return NULL_CACHE if @with_ignore_cache || !cache_enabled

    @cache
  end

  def evaluate(str)
    result = vim.echo(str)
    raise ReadError, result if VIM_EXCEPTION_REGEXP.match?(result)

    result
  end

  def vim
    vim_client_getter.call
  end
end
