# frozen_string_literal: true

require 'active_support/core_ext/module/attribute_accessors'

module Configuration
  extend PlatformCheck

  module_function

  mattr_accessor :root,
                 :vimrunner_switch_to_neovim_callback_scope

  def nvim_path
    @nvim_path ||=
      if linux?
        bin_dir.join('squashfs-root', 'usr', 'bin', 'nvim').to_s
      else
        bin_dir.join('nvim-osx64', 'bin', 'nvim').to_s
      end
  end

  def vim_gui?
    # NOTE: for some reason non-gui deadlocks on travis
    ENV.fetch('VIM_GUI', '1') == '1' && gui?
  end

  def nvim_gui?
    # NOTE use non-gui neovim on travis to not mess with opening xterm or iterm
    ENV.fetch('NVIM_GUI', '1') == '1' && gui?
  end

  def gui?
    ENV.fetch('GUI', '1') == '1'
  end

  def ci?
    ENV['TRAVIS_BUILD_ID'].present?
  end

  def bin_dir
    @bin_dir ||= Pathname.new(ENV.fetch('BIN_DIR') { root.join('spec', 'support', 'bin') })
  end

  def skip_compatibility_regexps?
    ENV.fetch('SKIP_COMPATIBILITY_REGEXPS', '0') == '1' || ci?
  end

  def plugins_dir
    @plugins_dir ||= Pathname.new(ENV.fetch('PLUGINS_DIR') { root.join('spec', 'support', 'vim_plugins') })
  end

  def dangerously_maximize_performance?
    # Required mostly for neovim backend testing which is super slow
    ENV['DANGEROUSLY_MAXIMIZE_PERFORMANCE'] == '1'
  end
end
