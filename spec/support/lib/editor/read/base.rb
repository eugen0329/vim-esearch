# frozen_string_literal: true

class Editor::Read::Base
  include VimlValue::SerializationHelpers

  VIM_EXCEPTION_REGEXP = /\AVim(\(echo\))?:E\d+:/
  class ReadError < RuntimeError; end

  attr_reader :vim_client_getter, :cache_enabled

  def initialize(vim_client_getter, cache_enabled)
    @vim_client_getter = vim_client_getter
    @cache_enabled = cache_enabled
  end

  def cache
    raise NotImplementedError
  end

  def clear_cache
    raise NotImplementedError
  end

  def with_ignore_cache
    raise NotImplementedError
  end

  def evaluated?(value)
    true
  end

  def with_ignore_cache
    @with_ignore_cache = true
    yield
  ensure
    @with_ignore_cache = false
  end

  private

  def evaluate(str)
    result = vim.echo(str)
    raise ReadError, result if VIM_EXCEPTION_REGEXP.match?(result)
    result
  end

  def vim
    vim_client_getter.call
  end
end
