# frozen_string_literal: true

require 'pathname'
require 'active_support'
require 'vimrunner/rspec'
require 'active_support/core_ext/numeric/time'
require 'rspec'
require 'active_support/dependencies'
require 'support/inflections'
require 'support/configuration'
require 'support/matchers/become_true_within.rb' # TODO: remove
require 'known_issues'
ActiveSupport::Dependencies.autoload_paths << 'spec/support'

SEARCH_UTIL_ADAPTERS = %w[ack ag git grep pt rg].freeze
PLUGIN_ROOT = Pathname.new(File.expand_path('..', __dir__))
BIN_DIR = PLUGIN_ROOT.join('spec', 'support', 'bin')

Fixtures::LazyDirectory.fixtures_directory = PLUGIN_ROOT.join('spec', 'fixtures')
Fixtures::LazyDirectory.fixtures_directory = PLUGIN_ROOT.join('spec', 'fixtures')
API::ESearch::Editor.cache_enabled = true

RSpec.configure do |config|
  config.include DSL::Vim
  config.include DSL::ESearch

  config.color_mode = true
  config.order = :rand
  config.formatter = :documentation
  config.fail_fast = ci? ? 3 : 10

  config.example_status_persistence_file_path = 'failed_specs.txt'
  config.filter_run_excluding :compatibility_regexp if ci?

  # overrule vimrunner
  config.around(:each) { |e| Dir.chdir(PLUGIN_ROOT, &e) }
end
RSpec::Matchers.define_negated_matcher :not_include, :include

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  config.start_vim do
    load_plugins!(vim_gui? ? Vimrunner.start_gvim : Vimrunner.start)
  end
end

VimrunnerNeovim::RSpec.configure do |config|
  config.reuse_server = false

  config.start_nvim do
    load_plugins!(VimrunnerNeovim::Server.new(
      nvim: nvim_path,
      gui: nvim_gui?,
      timeout: 10,
      verbose_level: 0
    ).start)
  end
end

def load_plugins!(vim)
  vimproc_path = PLUGIN_ROOT.join('spec', 'support', 'vim_plugins', 'vimproc.vim')
  pp_path      = PLUGIN_ROOT.join('spec', 'support', 'vim_plugins', 'vim-prettyprint')

  vim.add_plugin(PLUGIN_ROOT, 'plugin/esearch.vim')
  vim.add_plugin(vimproc_path,      'plugin/vimproc.vim')
  vim.add_plugin(pp_path,           'plugin/prettyprint.vim')
  vim
end

def nvim_path
  if linux?
    # PLUGIN_ROOT.join('spec', 'support', 'bin', "nvim.linux.appimage").to_s
    PLUGIN_ROOT.join('spec', 'support', 'bin', 'squashfs-root', 'usr', 'bin', 'nvim').to_s
  else
    PLUGIN_ROOT.join('spec', 'support', 'bin', 'nvim-osx64', 'bin', 'nvim').to_s
  end
end

# TODO: move out of here
def wait_for_search_start
  expect {
    press('lh') # press jk to close "Press ENTER or type command to continue" prompt
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

def esearch
  $facade ||= API::ESearch::Facade.new(self)
end

def ps_commands_without_sh
  ps_commands
    .split("\n")
    .reject { |l| %r{\A\s*(?:/bin/)?sh}.match?(l) }
    .join("\n")
end

def delete_current_buffer
  # From :help bdelete
  #   Unload buffer [N] (default: current buffer) and delete it from the buffer list.
  press ':bdelete<Enter>'
end
