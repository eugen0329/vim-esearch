# frozen_string_literal: true

require 'pathname'
require 'active_support'
require 'vimrunner/rspec'
require 'active_support/core_ext/numeric/time'
require 'rspec'
require 'active_support/dependencies'
require 'support/inflections'
require 'support/matchers/become_true_within' # TODO: remove
require 'known_issues'
ActiveSupport::Dependencies.autoload_paths << 'spec/support'

Configuration.tap do |c|
  c.root        = Pathname.new(File.expand_path('..', __dir__))
  c.bin_dir     = Pathname.new(ENV.fetch('BIN_DIR') { c.root.join('spec', 'support', 'bin') })
  c.plugins_dir = Pathname.new(ENV.fetch('PLUGINS_DIR') { c.root.join('spec', 'support', 'vim_plugins') })
end

RSpec.configure do |config|
  config.include DSL::Vim
  config.include DSL::ESearch

  config.color_mode = true
  config.order = :rand
  config.formatter = :documentation
  config.fail_fast = Configuration.ci? ? 3 : 10

  config.example_status_persistence_file_path = 'failed_specs.txt'
  config.filter_run_excluding :compatibility_regexp if Configuration.ci?

  # overrule vimrunner
  config.around(:each) { |e| Dir.chdir(Configuration.root, &e) }
end

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  config.start_vim do
    Configuration.load_plugins!(
      Configuration.vim_gui? ? Vimrunner.start_gvim : Vimrunner.start
    )
  end
end

VimrunnerNeovim::RSpec.configure do |config|
  config.reuse_server = true

  config.start_nvim do
    Configuration.load_plugins!(VimrunnerNeovim::Server.new(
      nvim: Configuration.nvim_path,
      gui: Configuration.nvim_gui?,
      timeout: 10,
      verbose_level: 0
    ).start)
  end
end

RSpec::Matchers.define_negated_matcher :not_include, :include

# Required mostly for improve performance of neovim backend testing by
# sacrificing reliability (as with every optimization which involves caching)
if Configuration.maximize_performance?
  API::ESearch::Editor.cache_enabled = true
  API::ESearch::Window::Entry.rollback_inside_buffer_on_open = false
  API::ESearch::Editor.cache_enabled = true
  ESEARCH = API::ESearch::Facade.new(-> { Vimrunner::Testing.instance })

  def esearch
    ESEARCH
  end
else
  API::ESearch::Editor.cache_enabled = false
  API::ESearch::Editor.cache_enabled = false
  API::ESearch::Window::Entry.rollback_inside_buffer_on_open = true

  def esearch
    @esearch ||= API::ESearch::Facade.new(-> { Vimrunner::Testing.instance })
  end
end

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
