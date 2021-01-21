# frozen_string_literal: true

require 'active_support/core_ext/module/attribute_accessors'
require_relative 'platform_check'

module Configuration
  extend PlatformCheck
  extend Vimrunner::Testing

  module_function

  mattr_accessor :root,
    :vimrunner_switch_to_neovim_callback_scope,
    :log,
    :search_event_timeout,
    :process_check_timeout,
    :search_freeze_timeout

  def test_env_number
    # For parallel_tests and parallel_split_test
    # Imitation of --first-is-1 of parallel_tests for parallel_split_test as it
    # doesn't have this option
    env_fetch('TEST_ENV_NUMBER') { '1' }
  end

  def log_level
    env_fetch('LOG_LEVEL') { 'info' }
  end

  def vim_path
    if vim_gui?
      Vimrunner::Platform.gvim
    else
      Vimrunner::Platform.vim
    end
  end

  def vimrc_path
    @vimrc_path ||= viml_dir.join('vimrunner.vim').to_s
  end

  def viml_dir
    root.join('spec', 'support', 'viml')
  end

  def debug_specs_performance?
    env_fetch('DEBUG_SPECS_PERFORMANCE') { ci? ? '0' : '1' } == '1'
  end

  def editor_throttle_interval
    env_fetch('EDITOR_THROTTLE_INTERVAL', 0.0).to_f
  end

  def screenshot_failures?
    env_fetch('SCREENSHOT_FAILURES') { ci? ? '0' : '1' } == '1'
  end

  def vim_gui?
    # NOTE: for some reason non-gui deadlocks on travis
    env_fetch('VIM_GUI', '1') == '1' && gui?
  end

  def nvim_gui?
    # NOTE: use non-gui neovim on travis to not mess with opening xterm or iterm
    env_fetch('NVIM_GUI', '1') == '1' && gui?
  end

  def gui?
    env_fetch('GUI', '1') == '1'
  end

  def ci?
    ENV['TRAVIS_BUILD_ID'].present?
  end

  def scripts_dir
    @scripts_dir ||= Pathname(env_fetch('SCRIPTS_DIR') { root.join('spec', 'support', 'scripts') })
  end

  def plugins_dir
    @plugins_dir ||= Pathname(env_fetch('PLUGINS_DIR') { '~/.cache/esearch-dev/plugins' }).expand_path
  end

  def dangerously_maximize_performance?
    # Required mostly for neovim backend testing which is super slow
    env_fetch('DANGEROUSLY_MAXIMIZE_PERFORMANCE', '1') == '1'
  end

  def env_fetch(key, default = nil)
    value = ENV[key]

    if value.blank?
      return yield(key) if block_given?

      return default
    end

    value
  end
end
