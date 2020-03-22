# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'digest'
require 'active_support/core_ext/class/attribute'

class Fixtures::LazyDirectory
  class_attribute :fixtures_directory
  attr_reader :given_name
  attr_accessor :files

  def initialize(files = [], given_name = nil)
    @files = files
    @given_name = given_name
  end

  def persist!
    directory_path = path

    # TODO
    # if persisted?
    #   files.each { |f| f.working_directory = directory_path }
    #   return self
    # end

    FileUtils.mkdir_p(directory_path)
    files.each do |f|
      f.working_directory = directory_path
      f.persist!
    end

    ensure_git_index_up_to_date

    self
  end

  def ensure_git_index_up_to_date
    system("git init #{fixtures_directory} ") unless File.directory?(dot_git)
    system("git -C #{fixtures_directory} add #{fixtures_directory}")
  end

  def rm_rf
    FileUtils.remove_dir(path)
    @files.freeze
    @given_name.freeze

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

  def dot_git
    @dot_git ||= fixtures_directory.join('.git')
  end

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
