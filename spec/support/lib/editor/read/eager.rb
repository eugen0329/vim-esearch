# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/cache'

class Editor::Read::Eager < Editor::Read::Base
  NULL_CACHE = ::ActiveSupport::Cache::NullStore.new

  def initialize(vim_client_getter, cache_enabled)
    super(vim_client_getter, cache_enabled)
    @cache = CacheStore.new
  end

  def echo(serializable_argument)
    cache.fetch(serializable_argument) do
      VimlValue.load(evaluate(VimlValue.dump([serializable_argument])))[0]
    end
  end

  def clear_cache
    cache.clear
  end

  def cache
    return NULL_CACHE if @with_ignore_cache || !cache_enabled

    @cache
  end
end
