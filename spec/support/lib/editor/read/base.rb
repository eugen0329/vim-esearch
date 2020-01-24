# frozen_string_literal: true

class Editor::Read::Base
  include VimlValue::SerializationHelpers
  attr_reader :vim_client_getter

  class ReadError < RuntimeError; end

  VIM_EXCEPTION_REGEXP = /\AVim(\(echo\))?:E\d+:/

  def initialize(vim_client_getter)
    @vim_client_getter = vim_client_getter
  end

  def cache
    raise NotImplementedError
  end

  def with_ignore_cache
    raise NotImplementedError
  end

  def evaluated?(value)
    true
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
