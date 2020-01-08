# frozen_string_literal: true

require 'active_support/hash_with_indifferent_access'
# require 'active_support/cache/memory_store'

class CacheStore < HashWithIndifferentAccess
  def fetch(key)
    super(key) do
      payload = yield
      # puts "miss #{key} #{payload}"
      self[key] = payload
      payload
    end
  end
  alias write_multi merge!
  alias exists? key?
end
