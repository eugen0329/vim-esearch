# frozen_string_literal: true

require 'active_support/core_ext/module/attribute_accessors'
require_relative 'platform_check'

module Configuration
  extend PlatformCheck

  module_function

  mattr_accessor :root,
    :vimrunner_switch_to_neovim_callback_scope,
    :log,
    :search_event_timeout,
    :process_check_timeout,
    :search_freeze_timeout

  def pt_path
    env_fetch('PT_PATH') { bin_dir.join('pt') }
  end

  def rg_path
    env_fetch('RG_PATH') { bin_dir.join('rg') }
  end

  def log_level
    env_fetch('LOG_LEVEL') { 'info' }
  end

  def nvim_path
    @nvim_path ||= env_fetch('NVIM_PATH') do
      if linux?
        bin_dir.join('squashfs-root', 'usr', 'bin', 'nvim').to_s
      else
        bin_dir.join('nvim').to_s
      end
    end
  end

  def vim_path
    @vim_path ||= env_fetch('VIM_PATH') do
      if vim_gui?
        Vimrunner::Platform.gvim
      else
        Vimrunner::Platform.vim
      end
    end
  end

  def vimrc_path
    @vimrc_path ||= root.join('spec', 'support', 'vimrc.vim').to_s
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
    # NOTE use non-gui neovim on travis to not mess with opening xterm or iterm
    env_fetch('NVIM_GUI', '1') == '1' && gui?
  end

  def gui?
    env_fetch('GUI', '1') == '1'
  end

  def ci?
    ENV['TRAVIS_BUILD_ID'].present?
  end

  def bin_dir
    @bin_dir ||= Pathname(env_fetch('BIN_DIR') { root.join('spec', 'support', 'bin') })
  end

  def scripts_dir
    @scripts_dir ||= Pathname(env_fetch('SCRIPTS_DIR') { root.join('spec', 'support', 'scripts') })
  end

  def skip_compatibility_regexps?
    env_fetch('SKIP_COMPATIBILITY_REGEXPS', '1') == '1' || ci?
  end

  def plugins_dir
    @plugins_dir ||= Pathname(env_fetch('PLUGINS_DIR') { root.join('spec', 'support', 'vim_plugins') })
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
