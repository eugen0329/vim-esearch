require 'fileutils'
require 'pathname'
require 'digest'
require 'active_support/core_ext/class/attribute'

module Fixtures
  class LazyDirectory
    class_attribute :fixtures_directory
    attr_reader :files

    def initialize(files = [])
      @files = files
    end

    def persist!
      FileUtils.mkdir_p(path.to_s) unless ::File.directory?(path.to_s)
      files.each { |f| f.persist!(path) }
      # todo verify that no redundant file in the directory
      self
    end

    def to_s
      path.to_s
    end

    private

    def path
      Pathname.new(self.fixtures_directory.join(name))
    end

    def name
      Digest::MD5.hexdigest(files.map(&:digest_key).sort.to_s)
    end
  end
end
