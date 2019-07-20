module Support
  module DSL
    module ESearch

      def esearch_settings(options)
        # elems = options.map { |name, val| "'#{name}': '#{val}'" }
        # dict = "{ #{elems.join(',')} }"

        # vim.multiline_command(%{
        #   if !exists('g:esearch')
        #     let g:esearch = #{dict}
        #   else
        #     call extend(g:esearch, #{dict})
        #   endif
        # })


        pairs = options.map do |name, val|
          val = "'#{val}'" unless val.is_a? Numeric
          "'#{name}': #{val}"
        end
        dict = "{ #{pairs.join(',')} }"
        vim.normal(":if !exists('g:esearch') | let g:esearch = #{dict} | else | call extend(g:esearch, #{dict}) | endif<Enter><Enter>")
      end
    end
  end
end
