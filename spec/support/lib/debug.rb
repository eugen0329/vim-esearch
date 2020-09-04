# frozen_string_literal: true

require 'pathname'
require 'mkmf'
require 'English' # reference global vars by human readable names

module Debug
  extend VimlValue::SerializationHelpers
  extend self # instead of module_function to maintain private methods
  UNWANTED_CONFIGS = %w[
    adapters
    current_adapter
    reusable_buffers_manager
    opened_buffers_manager
    middleware
    win_map
    undotree
    remember
  ].freeze

  def global_configuration
    reader.echo(var('g:esearch'))
  rescue Editor::Read::Base::ReadError => e
    e.message
  end

  def buffer_configuration
    reader.echo(var('b:esearch'))
  rescue Editor::Read::Base::ReadError => e
    e.message
  end

  def sourced_scripts
    reader.echo_command('scriptnames').split("\n")
  end

  def working_directories
    paths = reader.echo([var('$PWD'), func('getcwd')]).map { |p| Pathname(p) }
    result = ['$PWD', 'getcwd()'].zip(paths).to_h
    result['cwd_content'] = Dir.entries(result['getcwd()']) - ['.', '..'] if File.directory?(result['getcwd()'])
    result
  end

  def user_autocommands
    reader.echo_command('au User').split("\n")
  end

  def buffers
    reader.echo_command('ls!').split("\n")
  end

  def runtimepaths
    reader.echo(var('&runtimepath')).split(',')
  end

  def plugin_log(path: '/tmp/esearch.log')
    readlines(path)
  end

  def running_processes
    `ps -A -o pid,command`.split("\n")
  end

  def verbose_log
    return readlines(server.verbose_log_file) if neovim?

    nil
  end

  def nvim_log
    return readlines(server.nvim_log_file) if neovim?

    nil
  end

  def messages
    reader.echo(func('execute', 'messages')).split("\n")
  end

  def buffer_content
    reader.echo func('getline', 1, func('line', '$'))
  end

  def screenshot!(name = nil, directory: Configuration.root)
    if name.nil?
      timestamp = Time.now.strftime('%H_%M_%S_%L')
      name = "screenshot_#{timestamp}.png"
    end

    path = Pathname(directory).join(name)

    unless find_executable0('scrot')
      Configuration.log.warn("Can't find scrot executable")
      return nil
    end

    `scrot #{path}`
    return path if $CHILD_STATUS.success?

    nil
  end

  def neovim?
    server.is_a?(VimrunnerNeovim::Server)
  end

  private

  def filter_config(config)
    config.reject { |k, _v| UNWANTED_CONFIGS.include?(k) }
  end

  # Eager reader with disabled caching is used for reliability
  def reader
    @reader ||= Editor::Read::Eager.new(Configuration.method(:vim), false)
  end

  def readlines(path)
    return File.readlines(path).map(&:chomp) if File.exist?(path)

    nil
  end

  def server
    Configuration.vim.server
  end
end
