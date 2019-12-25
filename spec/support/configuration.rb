require 'rbconfig'

def vim_gui?
  # NOTE: for some reason non-gui deadlocks on travis
  ENV.fetch('VIM_GUI', '1') == '1' && gui?
end

def nvim_gui?
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
