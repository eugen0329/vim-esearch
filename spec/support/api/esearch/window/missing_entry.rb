# frozen_string_literal: true

API::ESearch::Window::MissingEntry = Struct.new(:relative_path, :line_in_file) do
  def empty?
    true
  end

  def line_content
    nil
  end
end
