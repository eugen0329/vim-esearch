require 'fileutils'
require 'pathname'

module Fixtures
  class LazyFile
    attr_reader :relative_path, :content

    def initialize(relative_path, content)
      @relative_path = Pathname.new(relative_path).cleanpath.to_s
      @content = content
    end

    def persist!(search_directory_path)
      absolute_path = search_directory_path.join(relative_path)
      file_directory_path = ::File.dirname(absolute_path.to_s)
      FileUtils.mkdir_p(file_directory_path) unless ::File.directory?(file_directory_path)
      ::File.open(absolute_path, 'w')  { |f| f.puts(content) }
    end

    def digest_key
      [relative_path, content].map(&:to_s).to_s
    end
  end
end
