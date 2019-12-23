# frozen_string_literal: true

module API
  module Esearch
    class Configuration
      attr_reader :spec

      def initialize(spec)
        @spec = spec
      end

      def configure!(options)
        dict = to_vim_dict(options)
        spec.vim.command("if !exists('g:esearch') | "\
                   "let g:esearch = #{dict} | "\
                   'else | '\
                   "call extend(g:esearch, #{dict}) | "\
                   'endif')
      end

      private

      def to_vim_dict(options)
        pairs = options.map do |name, val|
          val = "'#{val}'" unless val.is_a? Numeric
          "'#{name}': #{val}"
        end
        "{#{pairs.join(',')}}"
      end
    end
  end
end
