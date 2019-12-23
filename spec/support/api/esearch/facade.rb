# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

module API
  module Esearch
    class Facade
      attr_reader :configuration, :editor, :output, :core, :spec

      delegate :search!, to: :core
      delegate :configure!, to: :configuration
      delegate :cd!,        to: :editor

      delegate :has_search_started?,
               :has_search_finished?,
               :has_output_1_result?,
               to: :output

      def initialize(spec)
        @spec          = spec
        @configuration = Configuration.new(spec)
        @editor        = Editor.new(spec)
        @output        = Window.new(spec)
        @core          = Core.new(spec)
      end
    end
  end
end
