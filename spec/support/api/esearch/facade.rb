# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

class API::ESearch::Facade
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
    @spec = spec
  end

  # rubocop:disable Lint/DuplicateMethods
  def editor
    @editor ||= API::ESearch::Editor.new(spec)
  end

  def configuration
    @configuration ||= API::ESearch::Configuration.new(spec, editor)
  end

  def output
    @output ||= API::ESearch::Window.new(spec, editor)
  end

  def core
    @core ||= API::ESearch::Core.new(spec, editor)
  end
  # rubocop:enable Lint/DuplicateMethods
end
