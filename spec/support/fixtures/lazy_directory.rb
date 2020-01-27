# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'digest'
require 'active_support/core_ext/class/attribute'

class Fixtures::LazyDirectory
  class_attribute :fixtures_directory
  attr_reader :files, :given_name

  def initialize(files = [], given_name = nil)
    @files = files
    @given_name = given_name
  end

  def persist!
    directory_path = path

    if persisted?
      files.each { |f| f.working_directory = directory_path }
      return self
    end

    FileUtils.mkdir_p(directory_path)
    files.each do |f|
      f.working_directory = directory_path
      f.persist!
    end

    self
  end

  def to_s
    path.to_s
  end

  def path
    Pathname(fixtures_directory.join(name)).cleanpath
  end

  def name
    given_name || digest_name
  end

  private

  def digest_name
    Digest::MD5.hexdigest(files.map(&:digest_key).sort.to_s)
  end

  # We cannot be 100% sure that everything is persisted when `@given_name` is
  # specified, so it's required to check the files. Otherwise, `#name` is
  # generated based on the directory content so checking if the directory
  # exists is enough
  # TODO figure out a better name as the current is  misleading
  def persisted?
    !given_name && path.directory?
  end
end
