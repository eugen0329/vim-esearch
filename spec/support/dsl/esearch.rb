module Support
  module DSL
    module ESearch

      def esearch_settings(options)
        options.each do |name, value|
          # TODO
          vim.command("if !exists('g:esearch') | let g:esearch = {'#{name}': '#{value}'} | else | let g:esearch.#{name} = '#{value}' | endif")
        end
      end
    end
  end
end
