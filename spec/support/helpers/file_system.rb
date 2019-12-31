# frozen_string_literal: true

module Helpers::FileSystem
  extend ActiveSupport::Concern

  # Normally we shouldn't do any setup outside `it` blocks, but as far as all the
  # files are lazy then it's not an issue
  delegate :file, to: :class

  class_methods do
    def file(...)
      Fixtures::LazyFile.new(...)
    end
  end

  def directory(...)
    Fixtures::LazyDirectory.new(...)
  end
end
