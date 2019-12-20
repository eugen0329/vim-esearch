# frozen_string_literal: true

require 'pathname'
require 'vimrunner'
require 'vimrunner/rspec'
require 'active_support/core_ext/numeric/time.rb'
Dir[File.expand_path('spec/support/**/*.rb')].sort.each { |f| require f unless f.include?('brew_formula') }

SEARCH_UTIL_ADAPTERS = %w[ack ag git grep pt rg].freeze

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  config.start_vim do
    nvim_executable = working_directory.join('spec', 'support', 'bin', 'nvim.appimage')
    vim = Vimrunner::NeovimServer.new(nvim: nvim_executable.to_s).start
# Server.new(:executable => Platform.gvim).start(&blk)
    # vim =
    #   if gui?
    #     Vimrunner.start_gvim
    #   else
    #     Vimrunner.start # NOTE: for some reason it deadlocks on travis
    #   end
    sleep 1

    vimproc_path = working_directory.join('spec', 'support', 'vim_plugins', 'vimproc.vim')
    pp_path      = working_directory.join('spec', 'support', 'vim_plugins', 'vim-prettyprint')

    vim.add_plugin(working_directory, working_directory.join('plugin', 'esearch.vim'))
    vim.add_plugin(vimproc_path,      vimproc_path.join('plugin', 'vimproc.vim'))
    vim.add_plugin(pp_path,           pp_path.join('plugin', 'prettyprint.vim'))
    vim
  end
end

RSpec.configure do |config|
  config.include Support::DSL::Vim
  config.include Support::DSL::ESearch

  config.color_mode = true
  config.order = :rand
  config.formatter = :documentation
  config.fail_fast = 3
end

RSpec::Matchers.define_negated_matcher :not_include, :include

def gui?
  ENV.fetch('GUI', '1') == '1'
end

def ci?
  ENV['TRAVIS_BUILD_ID'].present?
end

# TODO: move out of here
def wait_for_search_start
  expect {
    press('j') # press j to close "Press ENTER or type command to continue" prompt
    bufname('%') =~ /Search/
  }.to become_true_within(20.second)
end

def wait_for_search_freezed(timeout = 3.seconds)
  expect { line(1) =~ /Finish/i }.not_to become_true_within(timeout)
end

def wait_for_qickfix_enter
  expect {
    expr('&filetype') == 'qf'
  }.to become_true_within(5.second)
end

def ps_commands
  `ps -A -o command | sed 1d`
end

def ps_commands_without_sh
  ps_commands
    .split("\n")
    .reject { |l| %r{\A\s*(?:/bin/)?sh}.match?(l) }
    .join("\n")
end

def working_directory
  @working_directory ||= Pathname.new(File.expand_path('..', __dir__))
end

def delete_current_buffer
  # From :help bdelete
  #   Unload buffer [N] (default: current buffer) and delete it from the buffer list.
  press ':bdelete<Enter>'
end
