# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'digest'
require 'shellwords'
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

    FileUtils.mkdir_p(directory_path)
    system("git init #{path} >/dev/null 2>&1") unless File.directory?(dot_git)

    files.each do |f|
      f.working_directory = directory_path
      f.persist!
      system("git -C #{Shellwords.escape(path)} add #{Shellwords.escape(f.path)} >/dev/null 2>&1")
      system("git -C #{Shellwords.escape(path)} commit -m #{Shellwords.escape(f.path)} >/dev/null 2>&1")
    end

    self
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
    @dot_git ||= path.join('.git')
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
