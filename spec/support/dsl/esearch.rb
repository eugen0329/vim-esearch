module Support
  module DSL
    module ESearch

      def esearch_settings(options)
        elems = options.map { |name, val| "'#{name}': '#{val}'" }
        dict = "{ #{elems.join(',')} }"

        vim.normal(":if !exists('g:esearch') | let g:esearch = #{dict} | else | call extend(g:esearch, #{dict}) | endif<Enter><Enter>")
      end
    end
  end
end
