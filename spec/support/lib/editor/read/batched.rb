# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/cache'

class Editor::Read::Batched < Editor::Read::Base
  NULL_CACHE = ::ActiveSupport::Cache::NullStore.new

  attr_reader :batch

  def initialize(vim_client_getter, cache_enabled)
    super(vim_client_getter, cache_enabled)
    @batch = Batch.new(method(:eager!))
    @cache = CacheStore.new
  end

  def echo(serializable_argument)
    container = Container.new(serializable_argument, batch)
    batch.push(container)
    container
  end

  def evaluated?(container)
    !container.__value__.equal?(Editor::Read::Batched::Container::UNDEFINED)
  end

  def clear_cache
    eager!
    cache.clear
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
      .evaluate! { |viml_values| VimlValue.load(evaluate(VimlValue.dump(viml_values))) }
      .write(cache)
      .clear

    true
  end
end
