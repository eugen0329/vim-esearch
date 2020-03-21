# frozen_string_literal: true

require 'active_support/cache'

class CacheStore < ActiveSupport::Cache::MemoryStore
  include CleanCaller

  def data
    @data.transform_values(&:value)
  end

  def clear(options = nil)
    instrument(:clear, nil, merged_options(options).merge(object_id: object_id)) do
      super
    end
  end

  def write(name, value, options = nil)
    instrument(:write_value, name, merged_options(options).merge(value: value)) do
      super
    end
  end
end
