# frozen_string_literal: true

require 'pathname'
require 'rspec'
require 'vimrunner/rspec'
require 'active_support/dependencies'
require 'active_support/core_ext/numeric/time'
require 'active_support/notifications'
require 'active_support/tagged_logging'
require 'batch-loader'
# reference global vars by human readable names (rubocop requirement)
require 'English'
begin
  require 'pry'
  Pry.config.history.file = '.pry_history'
rescue LoadError # rubocop:disable Lint/SuppressedException
end

require 'support/custom_matchers'
require 'support/inflections'
require 'support/subscriptions'
require 'known_issues'

require 'support/configuration'
Configuration.tap do |c|
  c.root = Pathname.new(File.expand_path('..', __dir__))
  c.log  = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT, level: c.log_level))
  c.search_event_timeout  = 8.seconds
  c.search_freeze_timeout = 10.second
  c.process_check_timeout = 10.second
end

ActiveSupport::Dependencies.autoload_paths << 'spec/support'

vim_instance_getter = if Configuration.debug_specs_performance?
                        -> { VimrunnerSpy.new(Vimrunner::Testing.instance) }
                      else
                        -> { Vimrunner::Testing.instance }
                      end

# Required mostly for improvimg performance of neovim backend testing by
# sacrificing reliability (as with every optimization which involves caching
# etc.). For other backends increase of running speed is about 1.5x - 2x times
if Configuration.dangerously_maximize_performance?
  API::Editor.cache_enabled = true
  API::ESearch::Window::Entry.rollback_inside_buffer_on_open = false
  VimrunnerNeovim::Server.remote_expr_execution_mode = :fallback_to_prepend_with_escape_press_on_timeout
  Configuration.vimrunner_switch_to_neovim_callback_scope = :all

  ESEARCH = API::ESearch::Facade.new(vim_instance_getter)
  def esearch
    ESEARCH
  end
else
  API::Editor.cache_enabled = false
  API::ESearch::Window::Entry.rollback_inside_buffer_on_open = true
  VimrunnerNeovim::Server.remote_expr_execution_mode = :prepend_with_escape_press
  Configuration.vimrunner_switch_to_neovim_callback_scope = :each

  API::ESearch::Window.search_event_timeout    = 16.seconds
  API::ESearch::Window.search_freeze_timeout   = 10.seconds
  API::ESearch::QuickFix.search_event_timeout  = 16.seconds
  API::ESearch::QuickFix.search_freeze_timeout = 10.seconds
  API::ESearch::Platform.process_check_timeout = 20.seconds

  def esearch
    @esearch ||= API::ESearch::Facade.new(vim_instance_getter)
  end
end

RSpec.configure do |c|
  c.include DSL::Vim
  c.include DSL::ESearch

  c.color_mode = true
  c.order = :rand
  c.seed = 1
  c.formatter = :documentation
  c.fail_fast = Configuration.ci? ? 3 : 1
  c.example_status_persistence_file_path = 'failed_specs.txt'
  c.filter_run_excluding :compatibility_regexps if Configuration.skip_compatibility_regexps?
  c.define_derived_metadata { |meta| meta[Configuration.platform_name] = true }
  # overrule vimrunner
  c.around(:each) { |e| Dir.chdir(Configuration.root, &e) }
end

RSpec::Matchers.define_negated_matcher :not_include, :include
Fixtures::LazyDirectory.fixtures_directory = Configuration.root.join('spec', 'fixtures')

Vimrunner::RSpec.configure do |c|
  c.reuse_server = true

  c.start_vim do
    load_vim_plugins!(Vimrunner::Server.new(
      executable: Configuration.vim_path,
      vimrc:      Configuration.vimrc_path
    ).start)
  end
end

VimrunnerNeovim::RSpec.configure do |c|
  c.reuse_server = true

  c.start_nvim do
    load_vim_plugins!(VimrunnerNeovim::Server.new(
      nvim:          Configuration.nvim_path,
      gui:           Configuration.nvim_gui?,
      vimrc:         Configuration.vimrc_path,
      timeout:       10,
      verbose_level: 0
    ).start)
  end
end

def load_vim_plugins!(vim)
  vim.add_plugin(Configuration.root,                                'plugin/esearch.vim')
  vim.add_plugin(Configuration.plugins_dir.join('vimproc.vim'),     'plugin/vimproc.vim')
  vim.add_plugin(Configuration.plugins_dir.join('vim-prettyprint'), 'plugin/prettyprint.vim')
  vim
end

BACKTRACE_CLEANER = ActiveSupport::BacktraceCleaner.new.tap do |bc|
  bc.add_filter { |line| line.gsub(Configuration.root.to_s, '') }
end

def clean_caller
  BACKTRACE_CLEANER.clean(caller.tap(&:unshift))
end
