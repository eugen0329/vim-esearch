# frozen_string_literal: true

require 'rbconfig'
require 'active_support/core_ext/module/attribute_accessors'

module Configuration
  module_function

  mattr_accessor :root,
                 :plugins_dir,
                 :bin_dir,
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
    @vim_gui ||= ENV.fetch('VIM_GUI', '1') == '1' && gui?
  end

  def nvim_gui?
    # NOTE use non-gui neovim on travis to not mess with opening xterm or iterm
    @nvim_gui ||= ENV.fetch('NVIM_GUI', '1') == '1' && gui?
  end

  def gui?
    @gui ||= ENV.fetch('GUI', '1') == '1'
  end

  def platform_name
    @platform_name ||=
      if linux?
        :linux
      elsif osx?
        :osx
      else
        raise 'Unknown platform'
      end
  end

  def osx?
    @osx ||= !(RbConfig::CONFIG['host_os'] =~ /darwin/).nil?
  end

  def linux?
    @linux ||= !(RbConfig::CONFIG['host_os'] =~ /linux/).nil?
  end

  def ci?
    @ci ||= ENV['TRAVIS_BUILD_ID'].present?
  end

  def bin_dir
    @bin_dir ||= Pathname.new(ENV.fetch('BIN_DIR') { root.join('spec', 'support', 'bin') })
  end

  def plugins_dir
    @plugins_dir ||= Pathname.new(ENV.fetch('PLUGINS_DIR') { root.join('spec', 'support', 'vim_plugins') })
  end

  def dangerously_maximize_performance?
    # Required mostly for neovim backend testing
    @dangerously_maximize_performance ||= ENV['DANGEROUSLY_MAXIMIZE_PERFORMANCE'] == '1'
  end
end
