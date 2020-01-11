# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

class API::Editor::Read::Batched < API::Editor::Read::Base
  attr_reader :batch, :cache, :cache_enabled

  def eager!
    return false if batch.blank?

    batch
      .lookup!(cache)
      .evaluate! { |identifiers| deserialize(vim.echo(serialize(identifiers))) }
      .write(cache)
      .clear

    true
  end

  def cached?
    begin
      @echo_skip_evaluation = true
      identifier = yield
    ensure
      @echo_skip_evaluation = false
    end
    raise unless identifier.is_a? API::Editor::Serialization::Identifier

    cache.exist?(identifier)
  end

  def clear_cache
    eager!
    cache.clear
  end

  def echo(argument)
    return argument if @echo_skip_evaluation

    container = Container.new(argument, batch)
    batch.push(container)
    container
  end

  def initialize(read_proxy, vim_client_getter, cache_enabled)
    super(read_proxy, vim_client_getter)
    @batch = Batch.new(method(:eager!))
    @cache = CacheStore.new
    @cache_enabled = cache_enabled
  end
end
