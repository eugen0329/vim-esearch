# frozen_string_literal: true

require 'pathname'
require 'rspec'
require 'vimrunner/rspec'
require 'active_support/dependencies'
require 'active_support/core_ext/numeric/time'
require 'active_support/notifications'
require 'active_support/tagged_logging'
begin
  require 'pry'
  Pry.config.history.file = '.pry_history'
rescue LoadError # rubocop:disable Lint/SuppressedException
end

require 'support/inflections'
require 'support/subscriptions'
require 'known_issues'

require 'support/configuration'
Configuration.tap do |c|
  c.root = Pathname(File.expand_path('..', __dir__))
  c.log  = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT, level: c.log_level))
  c.search_event_timeout  = 8.seconds
  c.search_freeze_timeout = 10.second
  c.process_check_timeout = 10.second
end

ActiveSupport::Dependencies.autoload_paths += ['spec/support', 'spec/support/lib']
require 'support/client'
require 'support/server'

vim_instance_getter =
  if Configuration.debug_specs_performance?
    -> { VimrunnerSpy.new(Configuration.vim) }
  else
    Configuration.method(:vim)
  end

# Required mostly for improvimg performance of neovim backend testing by
# sacrificing reliability (as with every optimization which involves caching
# etc.). For other backends increase of running speed is about 1.5x - 2x times
if Configuration.dangerously_maximize_performance?
  Editor.cache_enabled = true
  Editor.reader_class = Editor::Read::Batched
  API::ESearch::Window::Entry.rollback_inside_buffer_on_open = false
  VimrunnerNeovim::Server.remote_expr_execution_mode = :fallback_to_prepending_with_escape_press_on_timeout
  Configuration.vimrunner_switch_to_neovim_callback_scope = :all

  ESEARCH = API::ESearch::Facade.new(vim_instance_getter)
  def esearch
    ESEARCH
  end
else
  Editor.cache_enabled = false
  Editor.reader_class = Editor::Read::Eager
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

def editor
  esearch.editor
end

RSpec.configure do |c|
  c.color_mode = true
  c.order      = :rand
  c.formatter  = :documentation
  c.fail_fast  = Configuration.ci? ? 3 : 2
  c.example_status_persistence_file_path = 'failed_specs.txt'
  c.define_derived_metadata { |meta| meta[Configuration.platform_name] = true }
  c.after(:each) { VimrunnerSpy.reset! } if Configuration.debug_specs_performance?
  # overrule vimrunner
  c.around(:each) { |e| Dir.chdir(Configuration.root, &e) }

  c.filter_run_excluding(:compatibility_regexps) if Configuration.skip_compatibility_regexps?
  c.filter_run_excluding(:neovim)
  c.filter_run_excluding(:osx_only) unless Configuration.osx?
  c.filter_run_excluding(:multibyte_commandline) # TODO

  c.define_derived_metadata(file_path: %r{/spec/plugin/window/}) do |metadata|
    metadata[:window] = true
  end
  c.define_derived_metadata(file_path: %r{/spec/unit/}) do |metadata|
    metadata[:unit] = true
  end
  c.define_derived_metadata(file_path: %r{/spec/lib/}) do |metadata|
    metadata[:unit] = true # consider to test separately
  end
end

Kernel.srand(RSpec.configuration.seed || 1) # make random calls reproducible using --seed=n
RSpec::Matchers.define_negated_matcher :not_include, :include
Fixtures::LazyDirectory.fixtures_directory = Configuration.root.join('spec', 'fixtures')

Vimrunner::RSpec.configure do |c|
  c.reuse_server = true

  c.start_vim do
    load_runtime!(Client.new(Server.vim(
      name:       "VIMRUNER#{Time.now.to_f}#{ENV['TEST_ENV_NUMBER']}",
      executable: Configuration.vim_path,
      vimrc:      Configuration.vimrc_path,
      timeout:    10
    ).start))
  end
end

VimrunnerNeovim::RSpec.configure do |c|
  c.reuse_server = true

  c.start_nvim do
    load_runtime!(Client.new(Server.neovim(
      name:          "NVIMRUNER#{Time.now.to_f}#{ENV['TEST_ENV_NUMBER']}",
      nvim:          Configuration.nvim_path,
      gui:           Configuration.nvim_gui?,
      vimrc:         Configuration.vimrc_path,
      timeout:       10,
      verbose_level: 0
    ).start))
  end
end

def load_runtime!(vim)
  vim.append_runtimepath(Configuration.viml_dir)
  vim.add_plugin(Configuration.root,                            'plugin/esearch.vim')
  vim.add_plugin(Configuration.plugins_dir.join('vimproc.vim'), 'plugin/vimproc.vim')
  ## Will be used for testing contex syntax highlights
  # vim.add_plugin(Configuration.plugins_dir.join('vim-colors-solarized'))
  vim
end
