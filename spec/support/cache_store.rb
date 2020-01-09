# frozen_string_literal: true

require 'active_support/hash_with_indifferent_access'
# require 'active_support/cache'
# CacheStore = ActiveSupport::Cache::MemoryStore

class CacheStore < HashWithIndifferentAccess
  include TaggedLogging

  def initialize(...)
    super
    log_debug { "initialize from #{clean_caller[1]}" }
  end

  def stats
    { }
  end

  def clear
    log_debug { 'clear_cachestore' }
    super
  end

  def fetch(key)
    super(key) do
      payload = yield
      self[key] = payload
      payload
    end
  end
  alias write_multi merge!
  alias write []=
  alias exist? key?
end
