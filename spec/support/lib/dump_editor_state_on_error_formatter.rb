# frozen_string_literal: true

require 'pp'

class DumpEditorStateOnErrorFormatter
  attr_reader :output

  RSpec::Core::Formatters.register self,
    :example_failed,
    :example_group_started,
    :example_group_finished

  def initialize(output)
    @output = output
    @group_level = 0
  end

  def example_failed(_notification)
    state_string = state_hash
                   .map { |key, value| "#{current_indentation}### #{key}:\n#{value}" }
                   .join("\n")
                   .concat("\n")

    output << colorize(state_string)
  end

  def example_group_started(_notification)
    @group_level += 1
  end

  def example_group_finished(_notification)
    @group_level -= 1
  end

  private

  def state_hash
    {
      buffers:              format_array(Debug.buffers),
      buffer_content:       format_array(Debug.buffer_content),
      working_directories:  format_hash(Debug.working_directories.transform_values(&:to_s)),
      buffer_configuration: format_hash(Debug.configuration('b:esearch')),
      messages:             format_array(Debug.messages),
      plugin_log:           format_array(Debug.plugin_log),
      screenshot_path:      prepend_indent(Debug.screenshot!),
      # global_configuration: format_hash(Debug.global_configuration),
      # running_processes:    format_array(Debug.running_processes),
      # runtimepaths:         format_array(Debug.runtimepaths),
      # sourced_scripts:      format_array(Debug.sourced_scripts),
      # user_autocommands:    format_array(Debug.user_autocommands),
    }
  end

  def format_hash(object)
    prepend_indent(PP.pp(object, String.new).gsub("\n", "\n#{current_indentation}"))
  end

  def format_array(object)
    prepend_indent(object&.join("\n#{current_indentation}"))
  end

  def prepend_indent(object)
    "#{current_indentation}#{object}"
  end

  def colorize(string)
    RSpec::Core::Formatters::ConsoleCodes.wrap(string, RSpec.configuration.detail_color)
  end

  def current_indentation
    '  ' * @group_level
  end
end
