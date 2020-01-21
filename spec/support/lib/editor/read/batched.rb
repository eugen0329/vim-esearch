# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/cache'

class Editor::Read::Batched < Editor::Read::Base
  NULL_CACHE = ::ActiveSupport::Cache::NullStore.new

  attr_reader :batch, :cache_enabled

  def initialize(read_proxy, vim_client_getter, cache_enabled)
    super(read_proxy, vim_client_getter)
    @batch = Batch.new(method(:eager!))
    @cache = CacheStore.new
    @cache_enabled = cache_enabled
  end

  def echo(argument)
    return argument if @echo_skip_evaluation

    container = Container.new(argument, batch)
    batch.push(container)
    container
  end

  def cached?
    begin
      @echo_skip_evaluation = true
      expression = yield
    ensure
      @echo_skip_evaluation = false
    end
    raise unless expression.is_a? VimlValue::Serializable::Expression

    cache.exist?(expression)
  end

  def evaluated?(container)
    container.__value__ != Editor::Read::Batched::Container::NULL
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
    return NULL_CACHE if @with_ignore_cache || !cache_enabled

    @cache
  end

  private

  def eager!
    return false if batch.blank?

    batch
      .lookup!(cache)
      .evaluate! { |viml_values| VimlValue.load(vim.echo(VimlValue.dump(viml_values))) }
      .write(cache)
      .clear

    true
  end
end
