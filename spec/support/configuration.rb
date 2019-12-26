# frozen_string_literal: true

require 'rbconfig'

# Will be refactored later
module Configuration
  mattr_accessor :root, :plugins_dir, :bin_dir

  module_function

  def nvim_path
    if linux?
      bin_dir.join('squashfs-root', 'usr', 'bin', 'nvim').to_s
    else
      bin_dir.join('nvim-osx64', 'bin', 'nvim').to_s
    end
  end

  def load_plugins!(vim)
    vim.add_plugin(root,                                'plugin/esearch.vim')
    vim.add_plugin(plugins_dir.join('vimproc.vim'),     'plugin/vimproc.vim')
    vim.add_plugin(plugins_dir.join('vim-prettyprint'), 'plugin/prettyprint.vim')
    vim
  end

  def vim_gui?
    # NOTE: for some reason non-gui deadlocks on travis
    ENV.fetch('VIM_GUI', '1') == '1' && gui?
  end

  def nvim_gui?
    # return true if ci? && linux?
    # NOTE use non-gui neovim on travis to not mess with opening xterm or iterm
    ENV.fetch('NVIM_GUI', '1') == '1' && gui?
  end

  def osx?
    !(RbConfig::CONFIG['host_os'] =~ /darwin/).nil?
  end

  def linux?
    !(RbConfig::CONFIG['host_os'] =~ /linux/).nil?
  end

  def gui?
    ENV.fetch('GUI', '1') == '1'
  end

  def ci?
    ENV['TRAVIS_BUILD_ID'].present?
  end

  def maximize_performance?
    # Required mostly for neovim backend testing
    ENV['MAXIMIZE_PERFORMANCE'] == '1'
  end
end
