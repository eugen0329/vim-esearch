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
Dir[File.expand_path('spec/support/matchers/*.rb')].each { |f| require f }

require 'support/inflections'


require 'support/configuration'
Configuration.tap do |c|
  c.root = Pathname.new(File.expand_path('..', __dir__))
  c.log  = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT, level: c.log_level))
  c.search_event_timeout  = 8.seconds
  c.search_freeze_timeout = 3.second
  c.process_check_timeout = 5.second
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

  API::ESearch::Window.search_event_timeout    = 16.seconds
  API::ESearch::Window.search_freeze_timeout   = 10.seconds
  API::ESearch::QuickFix.search_event_timeout  = 16.seconds
  API::ESearch::QuickFix.search_freeze_timeout = 10.seconds
  API::ESearch::Platform.process_check_timeout = 20.seconds

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

RSpec::Matchers.define_negated_matcher :not_include, :include
Fixtures::LazyDirectory.fixtures_directory = Configuration.root.join('spec', 'fixtures')

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

def load_vim_plugins!(vim)
  vim.add_plugin(Configuration.root,                                'plugin/esearch.vim')
  vim.add_plugin(Configuration.plugins_dir.join('vimproc.vim'),     'plugin/vimproc.vim')
  vim.add_plugin(Configuration.plugins_dir.join('vim-prettyprint'), 'plugin/prettyprint.vim')
  vim
end
