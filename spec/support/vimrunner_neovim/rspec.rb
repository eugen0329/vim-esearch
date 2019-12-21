require "timeout"
require "pty"
require 'active_support/concern'

require "vimrunner/errors"
require "vimrunner/client"
require "vimrunner/platform"

require_relative 'server'

# almost copypasted from vimrunner due to poor extensibility

module VimrunnerNeovim
  module Testing
    class << self
      attr_accessor :neovim_instance
    end

    def neovim
      Testing.neovim_instance ||= RSpec.configuration.start_neovim_method.call
    end

    def use_neovim
      instance_old = Vimrunner::Testing.instance
      Vimrunner::Testing.instance = neovim
      yield
    ensure
      Vimrunner::Testing.instance = instance_old
    end
  end

  module RSpec
    class Configuration
      attr_accessor :reuse_server

      def start_neovim(&block)
        @start_neovim_method = block
      end

      def start_neovim_method
        @start_neovim_method
      end
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield configuration
    end
  end
end

Vimrunner::RSpec.configure do |config|
  config.reuse_server = false
end

RSpec.configure do |config|
  config.include(VimrunnerNeovim::Testing)

  config.before(:each) do
    unless Vimrunner::RSpec.configuration.reuse_server
      VimrunnerNeovim::Testing.instance.kill if VimrunnerNeovim::Testing.instance
      VimrunnerNeovim::Testing.instance = nil
    end
  end

  config.after(:suite) do
    VimrunnerNeovim::Testing.neovim_instance&.kill
  end
end