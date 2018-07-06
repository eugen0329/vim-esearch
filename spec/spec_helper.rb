require 'pathname'
require 'vimrunner'
require 'vimrunner/rspec'
require 'active_support/core_ext/numeric/time.rb'
require 'retryable'
Dir[File.expand_path('spec/support/**/*.rb')].each {|f| require f}

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  plug_path    = Pathname.new(File.expand_path('../../', __FILE__))
  vimproc_path = plug_path.join('.dep', 'vimproc.vim')
  pp_path      = plug_path.join('.dep', 'vim-prettyprint')

  config.start_vim do
    vim = Vimrunner.start_gvim
    sleep 1
    vim.add_plugin(plug_path,    plug_path.join('plugin', 'esearch.vim'))
    vim.add_plugin(vimproc_path, vimproc_path.join('plugin', 'vimproc.vim'))
    vim.add_plugin(pp_path,      vimproc_path.join('plugin', 'prettyprint.vim'))
    vim
  end
end

RSpec.configure do |config|
  config.include Support::DSL::Vim
  config.include Support::DSL::ESearch
end

def working_directory
  @working_directory ||= ENV.fetch('TRAVIS_BUILD_DIR') { Pathname.new(File.expand_path('../../', __FILE__)) }
end
