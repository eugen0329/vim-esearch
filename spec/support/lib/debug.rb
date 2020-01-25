# frozen_string_literal: true

require 'pathname'
require 'shellwords'

module Debug
  extend VimlValue::SerializationHelpers

  module_function

  def global_configuration
    reader.echo(var('g:esearch'))
  rescue Editor::Read::Base::ReadError => e
    e.message
  end

  def buffer_configuration
    reader.echo(var('b:esearch')).except('request')
  rescue Editor::Read::Base::ReadError => e
    e.message
  end

  def request_configuration
    reader.echo(var('b:esearch'))['request']
  rescue Editor::Read::Base::ReadError => e
    e.message
  end

  def sourced_scripts
    reader.echo_command('scriptnames').split("\n")
  end

  def working_directories
    paths = reader.echo([var('$PWD'), func('getcwd')]).map { |p| Pathname(p) }
    ['$PWD', 'getcwd()'].zip(paths).to_h
  end

  def user_autocommands
    reader.echo_command('au User').split("\n")
  end

  def buffers
    reader.echo_command('ls!').split("\n")
  end

  def runtimepath
    reader.echo(var('&runtimepath')).split(',')
  end

  def messages
    reader.echo_command('messages').split("\n")
  end

  def update_time
    reader.echo(var('&ut'))
  rescue Editor::Read::Base::ReadError => e
    e.message
  end

  def buffer_content
    reader.echo func('getline', 1, func('line', '$'))
  end

  # TODO
  def screenshot
    shell_command.to_s

    prefix = 'screenshot'
    example_location = Pathname(RSpec.current_example.id).cleanpath.to_s.gsub(File::SEPARATOR, '_')
    timestamp = Time.now.strftime('%H_%M_%S')
    name = [prefix, timestamp, example_location].join('_')
    file_name = Shellwords.escape("#{name}.png")
    # `scrot #{file_name}`
    puts 'Failed to take a screenshot' unless $CHILD_STATUS.success?
  end

  def reader
    @reader ||= Editor::Read::Eager.new(Configuration.method(:vim), false)
  end
end
