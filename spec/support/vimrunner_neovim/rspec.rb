# frozen_string_literal: true

require 'timeout'
require 'pty'
require 'active_support/concern'

require 'vimrunner/errors'
require 'vimrunner/client'
require 'vimrunner/platform'

require_relative 'server'

# almost copypasted from vimrunner due to inability to write an extension for it

module VimrunnerNeovim
  module Testing
    class << self
      attr_accessor :nvim_instance
    end

    def nvim
      Testing.nvim_instance ||= RSpec.configuration.start_nvim_method.call
    end

    def use_nvim
      instance_old = Vimrunner::Testing.instance
      Vimrunner::Testing.instance = nvim
      yield
    ensure
      Vimrunner::Testing.instance = instance_old
    end
  end

  module RSpec
    class Configuration
      attr_accessor :reuse_server

      def start_nvim(&block)
        @start_nvim_method = block
      end

      attr_reader :start_nvim_method
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
    if VimrunnerNeovim::Testing.nvim_instance.present? &&
       !VimrunnerNeovim::Testing.nvim_instance.server&.running?
      puts 'Cleanup dead nvim_instance'
      VimrunnerNeovim::Testing.nvim_instance = nil # cleanup process if it's failed
    end
  end

  config.after(:each) do
    unless VimrunnerNeovim::RSpec.configuration.reuse_server
      VimrunnerNeovim::Testing.nvim_instance&.kill
      VimrunnerNeovim::Testing.nvim_instance = nil
    end
  end

  config.after(:suite) do
    VimrunnerNeovim::Testing.nvim_instance&.kill
  end
end
