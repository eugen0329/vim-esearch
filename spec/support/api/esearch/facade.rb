require 'active_support/core_ext/module/delegation'

module API
  module Esearch
    class Facade
      attr_reader :configuration

      delegate :configure!, to: :configuration

      def initialize(spec)
        @spec = spec
        @configuration = Configuration.new(spec)
      end
    end
  end
end
