# frozen_string_literal: true

module Helpers::FileSystem
  extend ActiveSupport::Concern

  # Normally we shouldn't do any setup outside `it` blocks, but as far as all the
  # files are lazy then it's not an issue
  delegate :swap_file, :file, :directory, :repo, to: :class

  class_methods do
    def swap_file(...)
      Fixtures::LazySwapFile.new(...)
    end

    def file(...)
      Fixtures::LazyFile.new(...)
    end

    def directory(...)
      Fixtures::LazyDirectory.new(...)
    end

    def repo(...)
      Fixtures::LazyRepo.new(...)
    end
  end
end
