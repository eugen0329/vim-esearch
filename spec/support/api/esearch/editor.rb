# frozen_string_literal: true

module API
  module Esearch
    class Editor
      attr_reader :spec

      def initialize(spec)
        @spec = spec
      end

      def cd!(where)
        spec.press ":cd #{where}<Enter>"
      end
    end
  end
end
