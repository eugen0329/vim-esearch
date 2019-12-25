# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

module API
  module ESearch
    class Facade
      attr_reader :configuration, :editor, :output, :core, :spec

      delegate :search!, to: :core
      delegate :configure!, to: :configuration
      delegate :cd!,        to: :editor

      delegate :has_search_started?,
               :has_search_finished?,
               :has_reported_a_single_result?,
               :has_outputted_result_from_file_in_line?,
               :has_outputted_result_with_right_position_inside_file?,
               :has_not_reported_errors?,
               to: :output

      def initialize(spec)
        @spec          = spec
        @editor        = Editor.new(spec)
        @configuration = Configuration.new(spec, @editor)
        @output        = Window.new(spec, @editor)
        @core          = Core.new(spec, @editor)
      end
    end
  end
end
