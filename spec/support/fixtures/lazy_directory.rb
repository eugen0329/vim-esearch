# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'digest'
require 'active_support/core_ext/class/attribute'

class Fixtures::LazyDirectory
  class_attribute :fixtures_directory
  attr_reader :files

  def initialize(files = [])
    @files = files
  end

  def persist!
    directory_path = path
    return self if directory_path.directory?

    FileUtils.mkdir_p(directory_path.to_s)
    files.each { |f| f.persist!(directory_path) }
    self
  end

  def to_s
    path.to_s
  end

  private

  def path
    Pathname.new(fixtures_directory.join(name))
  end

  def name
    Digest::MD5.hexdigest(files.map(&:digest_key).sort.to_s)
  end
end
