# frozen_string_literal: true

require 'fileutils'
require 'pathname'

class Fixtures::LazyFile
  attr_reader :relative_path, :content, :kwargs

  def initialize(relative_path, content, **kwargs)
    @relative_path = Pathname.new(relative_path).cleanpath.to_s
    @content = content
    @kwargs = kwargs
  end

  def persist!(search_directory_path)
    absolute_path = search_directory_path.join(relative_path)
    file_directory_path = absolute_path.dirname
    FileUtils.mkdir_p(file_directory_path) unless file_directory_path.directory?
    File.open(absolute_path, open_mode) { |f| f.puts(content) }
  end

  def digest_key
    [relative_path, content].map(&:to_s).to_s
  end

  private

  def open_mode
    return 'wb' if kwargs[:binary]

    'w'
  end
end
