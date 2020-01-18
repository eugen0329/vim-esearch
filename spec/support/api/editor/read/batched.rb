# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

class API::Editor::Read::Batched < API::Editor::Read::Base
  attr_reader :batch, :cache_enabled

  def eager!
    return false if batch.blank?

    batch
      .lookup!(cache)
      .evaluate! { |viml_values| deserialize(vim.echo(serialize(viml_values))) }
      .write(cache)
      .clear

    true
  end

  def cached?
    begin
      @echo_skip_evaluation = true
      expression = yield
    ensure
      @echo_skip_evaluation = false
    end
    raise unless expression.is_a? API::Editor::Serialization::VimlExpr

    cache.exist?(expression)
  end

  def clear_cache
    eager!
    cache.clear
  end

  def with_ignore_cache
    @with_ignore_cache = true
    yield
  ensure
    @with_ignore_cache = false
  end

  def cache
    return @null_cache if @with_ignore_cache || !cache_enabled

    @cache
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
    @null_cache = ActiveSupport::Cache::NullStore.new
  end
end
