# frozen_string_literal: true

module Helpers::FileSystem
  extend ActiveSupport::Concern

  # Normally we shouldn't do any setup outside `it` blocks, but as far as all the
  # files are lazy then it's not an issue
  delegate :file, :directory, to: :class

  class_methods do
    def file(...)
      Fixtures::LazyFile.new(...)
    end

    def directory(...)
      Fixtures::LazyDirectory.new(...)
    end
  end

  # TODO: consider to do it with tempfiles mechanism
  def temporary_persist_and_add_to_index(directory)
    directory.persist!
    raise "failed with #{$CHILD_STATUS}" unless system("git add #{directory.path}")

    yield
  ensure
    raise "failed with #{$CHILD_STATUS}" unless system("git rm -r --cached #{directory.path}")

    directory.rm_rf
  end
end
