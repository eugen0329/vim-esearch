# frozen_string_literal: true

require 'pathname'
require 'mkmf'
require 'English' # reference global vars by human readable names

module Debug
  extend VimlValue::SerializationHelpers
  extend self # instead of module_function to maintain private methods
  UNWANTED_CONFIGS = %w[
    adapters _adapter reusable_buffers_manager opened_buffers_manager
    middleware win_map undotree remember hl_ctx_syntax last_pattern
    win_contexts_syntax_debounce_wait before win_cursor_linenr_highlight
    win_update_throttle_wait win_contexts_syntax_clear_on_files_count
    win_context_len_annotations win_viewport_off_screen_margin win_contexts_syntax
    loaded_lazy root_markers win_matches_highlight_debounce_wait pending_warnings
    final_batch_size context live_update_debounce_wait filetypes adapter after
    last_id win_contexts_syntax_clear_on_line_len ctx_by_name
  ].freeze

  def configuration(name)
    filter_config(reader.echo(var(name)))
  rescue Editor::Read::Base::ReadError => e
    e.message
  end

  def sourced_scripts
    reader.echo_command('scriptnames').split("\n")
  end

  def working_directories
    result = reader
             .echo({'$PWD': var('$PWD'), 'getcwd()': func('getcwd')})
             .transform_values { |path| Pathname(path) }
    result['cwd_content'] = cwd_content(result['getcwd()']) if File.directory?(result['getcwd()'])
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

  private

  def cwd_content(cwd)
    (Dir.entries(cwd) - ['.', '..'])
      .map { |path| [path, cwd.join(path)] }
      .map { |path, fullpath| fullpath.file? ? [path, fullpath.readlines] : [path, fullpath.ftype] }
      .sort
  end

  def filter_config(config)
    filtered = config
               .reject { |k, _v| UNWANTED_CONFIGS.include?(k) }
               .reject { |_k, v| v.is_a?(VimlValue::Types::Funcref) }
    filtered['request'].delete('jobstart_args') if filtered['request'].is_a? Hash
    filtered
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
