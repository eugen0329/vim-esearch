# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

class API::Editor::Read::MagicBatched < API::Editor::Read::Base
  class_attribute :cache, default: CacheStore.new

  def self.evaluate_batch!
    return false if Thread.current[:batch].blank?

    vim = esearch.editor.__send__(:vim)
    Batch
      .current
      .lookup!(cache)
      .evaluate! { |identifiers| deserialize(vim.echo(serialize(identifiers))) }
      .write(cache)
      .clear

    true
  end

  def clear_cache
    API::Editor::Read::MagicBatched.evaluate_batch!
    cache.clear
  end

  def self.vim
    Thread.current[:vim].call
  end

  delegate :serialize,   to: :serializer
  delegate :deserialize, to: :deserializer

  def echo(argument)
    Container.new(argument) # if @echo_return_unevaluated
  end

  def batch_echo(&block)
    yield(read_proxy)
    batch_arg = read_proxy.yield_self(&block)
  end

  def initialize(read_proxy, vim_client_getter, _cache_enabled)
    super(read_proxy, vim_client_getter)
  end
end
