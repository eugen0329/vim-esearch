# frozen_string_literal: true

require 'fileutils'
require 'pathname'

# TODO: reduce duplication with lazy file
class Fixtures::LazySwapFile
  attr_reader :raw_content, :lazy_file
  attr_accessor :working_directory

  def initialize(raw_content, lazy_file)
    @raw_content = raw_content
    @lazy_file = lazy_file
  end

  def persist!
    absolute_path = path
    FileUtils.mkdir_p(absolute_path.dirname) unless absolute_path.dirname.directory?
    File.open(absolute_path, open_mode) { |f| f.puts(content) }
    self
  end

  def path
    Pathname([
      lazy_file.path.dirname.to_s,
      [lazy_file.path.basename.to_s, '.swp'].join,
    ].join('/'))
  end

  def relative_path
    digest_name
  end

  def basename
    File.basename(relative_path)
  end

  def to_s
    path.to_s
  end

  def digest_key
    [relative_path, content].map(&:to_s).to_s
  end

  def lines
    content.split("\n")
  end

  def readlines
    File.readlines(path)
  end

  def unlink
    File.unlink(path)
  end

  def content
    @content ||=
      if raw_content.is_a? String
        raw_content
      elsif raw_content.is_a? Array
        raw_content.join("\n")
      elsif raw_content.nil?
        ''
      else
        raise ArgumentError
      end
  end

  def digest_name
    Digest::MD5.hexdigest(content.to_s)
  end

  def open_mode
    'wb'
  end
end
