require 'pathname'
require 'vimrunner'
require 'vimrunner/rspec'
require 'active_support/core_ext/numeric/time.rb'
require 'retryable'
Dir[File.expand_path('spec/support/**/*.rb')].each {|f| require f}

SEARCH_UTIL_ADAPTERS = ['ack', 'ag', 'git', 'grep', 'pt', 'rg'].freeze

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

RSpec::Matchers.define_negated_matcher :not_include, :include
def wait_search_start
  expect {
    press("j") # press j to close "Press ENTER or type command to continue" prompt
    bufname("%") =~ /Search/
  }.to become_true_within(5.second)
end

def wait_quickfix_enter
  expect {
    expr('&filetype') == 'qf'
  }.to become_true_within(5.second)
end

def ps_aux_without_sh_delegate_command
  `ps aux`
    .split("\n")
    .reject { |l| l.include?('sh -c') }
    .join("\n")
end

def working_directory
  @working_directory ||= ENV.fetch('TRAVIS_BUILD_DIR') { Pathname.new(File.expand_path('../../', __FILE__)) }
end

