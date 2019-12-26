# frozen_string_literal: true

require 'active_support/hash_with_indifferent_access'

class CacheStore < HashWithIndifferentAccess
  def fetch(key)
    super(key) do
      payload = yield
      # puts "miss #{key} #{payload}"
      self[key] = payload
      payload
    end
  end

  alias_method :write_multi, :merge!
end
