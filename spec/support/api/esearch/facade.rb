# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'

class API::ESearch::Facade
  attr_reader :configuration, :editor, :output, :core, :spec

  OUTPUTS = {
    win: API::ESearch::Window
  }.with_indifferent_access

  delegate :search!, to: :core
  delegate :configure, :configure!, to: :configuration
  delegate :cd!,        to: :editor

  delegate :has_search_started?,
    :has_search_finished?,
    :has_reported_a_single_result?,
    :has_outputted_result_from_file_in_line?,
    :has_outputted_result_with_right_position_inside_file?,
    :has_not_reported_errors?,
    :close_search!,
    to: :output

  def initialize(spec)
    @spec = spec
    @outputs = {}
  end

  # rubocop:disable Lint/DuplicateMethods
  def editor
    @editor ||= API::ESearch::Editor.new(spec)
  end

  def configuration
    @configuration ||= API::ESearch::Configuration.new(editor)
  end

  def output
    @outputs[configuration.output] ||= OUTPUTS.fetch(configuration.output).new(editor)
  end

  def core
    @core ||= API::ESearch::Core.new(editor)
  end
  # rubocop:enable Lint/DuplicateMethods
end
