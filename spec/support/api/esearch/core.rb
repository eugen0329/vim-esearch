# frozen_string_literal: true

module API
  module ESearch
    class Core
      attr_reader :spec, :editor

      def initialize(spec, editor)
        @spec = spec
        @editor = editor
      end

      def search!(search_string)
        editor.press! ":call esearch#init()<Enter>#{search_string}<Enter>"
      end
    end
  end
end
