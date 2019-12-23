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
               :has_output_1_result_in_header?,
               :has_output_result_in_file?,
               to: :output

      def initialize(spec)
        @spec          = spec
        @editor        = Editor.new(spec)
        @configuration = Configuration.new(spec)
        @output        = Window.new(spec, @editor)
        @core          = Core.new(spec)
      end
    end
  end
end
