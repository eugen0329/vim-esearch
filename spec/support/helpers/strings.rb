# frozen_string_literal: true

module Helpers::Strings
  REGEXP_WRAPPING_SLASHES = %r{\A/|/\w*\z}.freeze

  extend ActiveSupport::Concern

  class_methods do
    def dump(arg)
      case arg
      when String then arg.dump
      when Regexp then arg.inspect
      else arg.to_s
      end
    end
  end

  def to_search(search_string)
    return search_string.inspect.gsub(REGEXP_WRAPPING_SLASHES, '') if search_string.is_a? Regexp

    search_string.to_s
  end
end
