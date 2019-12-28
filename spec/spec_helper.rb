# frozen_string_literal: true

require 'pathname'
require 'rspec'
require 'vimrunner/rspec'
require 'active_support/dependencies'
require 'active_support/core_ext/numeric/time'
require 'active_support/tagged_logging'

require 'support/inflections'
require 'support/matchers/become_true_within' # TODO: remove
require 'known_issues'

require 'support/configuration'
Configuration.tap do |c|
  c.root = Pathname.new(File.expand_path('..', __dir__))
  c.log  = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT, level: c.log_level))
end

ActiveSupport::Dependencies.autoload_paths << 'spec/support'

# Required mostly for improvimg performance of neovim backend testing by
# sacrificing reliability (as with every optimization which involves caching
# etc.). For other backends increase of running speed is about 1.5x - 2x times
if Configuration.dangerously_maximize_performance?
  API::ESearch::Editor.cache_enabled = true
  API::ESearch::Window::Entry.rollback_inside_buffer_on_open = false
  VimrunnerNeovim::Server.remote_expr_execution_mode = :fallback_to_prepend_with_escape_press_on_timeout
  Configuration.vimrunner_switch_to_neovim_callback_scope = :all

  ESEARCH = API::ESearch::Facade.new(-> { Vimrunner::Testing.instance })
  def esearch
    ESEARCH
  end
else
  API::ESearch::Editor.cache_enabled = false
  API::ESearch::Window::Entry.rollback_inside_buffer_on_open = true
  VimrunnerNeovim::Server.remote_expr_execution_mode = :prepend_with_escape_press
  Configuration.vimrunner_switch_to_neovim_callback_scope = :each

  def esearch
    @esearch ||= API::ESearch::Facade.new(-> { Vimrunner::Testing.instance })
  end
end

RSpec.configure do |c|
  c.include DSL::Vim
  c.include DSL::ESearch

  c.color_mode = true
  c.order = :rand
  c.formatter = :documentation
  c.fail_fast = Configuration.ci? ? 3 : 10
  c.example_status_persistence_file_path = 'failed_specs.txt'
  c.filter_run_excluding :compatibility_regexps if Configuration.skip_compatibility_regexps?
  c.define_derived_metadata { |meta| meta[Configuration.platform_name] = true }
  # overrule vimrunner
  c.around(:each) { |e| Dir.chdir(Configuration.root, &e) }
end

Vimrunner::RSpec.configure do |c|
  c.reuse_server = true

  c.start_vim do
    load_vim_plugins!(
      Configuration.vim_gui? ? Vimrunner.start_gvim : Vimrunner.start
    )
  end
end

VimrunnerNeovim::RSpec.configure do |c|
  c.reuse_server = true

  c.start_nvim do
    load_vim_plugins!(VimrunnerNeovim::Server.new(
      nvim:          Configuration.nvim_path,
      gui:           Configuration.nvim_gui?,
      timeout:       10,
      verbose_level: 0
    ).start)
  end
end

RSpec::Matchers.define_negated_matcher :not_include, :include
Fixtures::LazyDirectory.fixtures_directory = Configuration.root.join('spec', 'fixtures')

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

def load_vim_plugins!(vim)
  vim.add_plugin(Configuration.root,                                'plugin/esearch.vim')
  vim.add_plugin(Configuration.plugins_dir.join('vimproc.vim'),     'plugin/vimproc.vim')
  vim.add_plugin(Configuration.plugins_dir.join('vim-prettyprint'), 'plugin/prettyprint.vim')
  vim
end
