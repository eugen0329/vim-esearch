# frozen_string_literal: true

require 'digest'
require 'active_support/hash_with_indifferent_access'
require 'active_support/cache'

class CacheStore < ActiveSupport::Cache::MemoryStore
  def write(name, value, options = nil)
    instrument(:write_value, name, merged_options(options).merge(value: value)) {}
    super
  end
end
