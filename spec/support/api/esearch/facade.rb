# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'

class API::ESearch::Facade
  attr_reader :vim_client_getter, :configuration, :editor, :output, :core

  OUTPUTS = {
    win:     API::ESearch::Window,
    qflist:  API::ESearch::QuickFix,
    stubbed: API::ESearch::StubbedOutput,
  }.with_indifferent_access

  delegate :search!, :input!, to: :core
  delegate :configure, :configure!, to: :configuration
  delegate :cd!, :edit!, :cleanup!, to: :editor
  delegate :grep_and_kill_process_by!,
    :has_no_process_matching?,
    to: :platform

  delegate :has_search_started?,
    :has_live_update_search_started?,
    :has_no_live_update_search_started?,
    :has_search_finished?,
    :has_output_message?,
    :has_valid_buffer_basename?,
    :has_reported_a_single_result?,
    :has_search_highlight?,
    :has_filename_highlight?,
    :has_outputted_result_from_file_in_line?,
    :has_not_reported_errors?,
    :has_search_freezed?,
    :close_search!,
    to: :output

  def initialize(editor)
    @outputs = {}
    @editor = editor
  end

  # rubocop:disable Lint/DuplicateMethods
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
