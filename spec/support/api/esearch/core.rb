# frozen_string_literal: true

module API
  module Esearch
    class Core
      attr_reader :spec

      def initialize(spec)
        @spec = spec
      end

      def search!(search_string)
        spec.press ":call esearch#init()<Enter>#{search_string}<Enter>"
      end
    end
  end
end
