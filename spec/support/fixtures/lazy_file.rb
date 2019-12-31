# frozen_string_literal: true

require 'fileutils'
require 'pathname'

class Fixtures::LazyFile
  attr_reader :relative_path, :content, :kwargs
  attr_accessor :working_directory

  def self.named_by_content(content, **kwargs)
    name = Digest::MD5
           .hexdigest([content, kwargs.to_a.sort].map(&:to_s).to_s)
    new(name, content, **kwargs)
  end

  def initialize(relative_path, content, **kwargs)
    @relative_path = Pathname.new(relative_path).cleanpath.to_s
    @content = content
    @kwargs = kwargs
  end

  def persist!
    FileUtils.mkdir_p(path.dirname) unless path.dirname.directory?
    File.open(path, open_mode) { |f| f.puts(content) } unless path.file?
    self
  end

  def digest_key
    [relative_path, content].map(&:to_s).to_s
  end

  def path
    working_directory.join(relative_path)
  end

  def to_s
    path.to_s
  end

  private

  def open_mode
    return 'wb' if kwargs[:binary]

    'w'
  end
end
