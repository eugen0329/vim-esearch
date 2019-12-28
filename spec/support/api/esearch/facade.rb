# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'

class API::ESearch::Facade
  attr_reader :vim_client_getter, :configuration, :editor, :output, :core

  OUTPUTS = {
    win:    API::ESearch::Window,
    qflist: API::ESearch::QuickFix
  }.with_indifferent_access

  delegate :search!, to: :core
  delegate :configure, :configure!,    to: :configuration
  delegate :cd!,                       to: :editor
  delegate :grep_and_kill_process_by!,
    :has_no_process_matching?,
    :has_running_processes_matching?,
    to: :platform

  delegate :has_search_started?,
    :has_search_finished?,
    :has_reported_a_single_result?,
    :has_outputted_result_from_file_in_line?,
    :has_outputted_result_with_right_position_inside_file?,
    :has_not_reported_errors?,
    :has_search_freezed?,
    :close_search!,
    to: :output

  def initialize(vim_client_getter)
    @outputs = {}
    @vim_client_getter = vim_client_getter
  end

  # rubocop:disable Lint/DuplicateMethods
  def editor
    @editor ||= API::ESearch::Editor.new(vim_client_getter)
  end

  def platform
    @platform ||= API::ESearch::Platform.new
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
