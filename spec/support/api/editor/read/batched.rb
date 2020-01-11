# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

class API::Editor::Read::Batched < API::Editor::Read::Base
  attr_reader :batch, :cache

  def eager!
    return false if batch.blank?

    batch
      .lookup!(cache)
      .evaluate! { |identifiers| deserialize(vim.echo(serialize(identifiers))) }
      .write(cache)
      .clear

    true
  end

  def clear_cache
    eager!
    cache.clear
  end

  def echo(argument)
    container = Container.new(argument, batch)
    batch.push(container)
    container
  end

  def initialize(read_proxy, vim_client_getter, _cache_enabled)
    super(read_proxy, vim_client_getter)
    @batch = Batch.new(method(:eager!))
    @cache = CacheStore.new
  end
end
