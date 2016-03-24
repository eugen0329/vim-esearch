require 'vimrunner'
require 'vimrunner/rspec'
require 'active_support/core_ext/numeric/time.rb'
require_relative 'support/vim/dsl'
Dir[File.expand_path('spec/support/matchers/*.rb')].each {|f| require f}

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  config.start_vim do
    vim = Vimrunner.start_gvim
    vim.add_plugin(File.expand_path('.'),              'plugin/easysearch.vim')
    vim.add_plugin(File.expand_path('../vimproc.vim'), '../vimproc.vim/plugin/vimproc.vim')
    vim
  end
end

RSpec.configure do |config|
  config.include Support::Vim::DSL
end
