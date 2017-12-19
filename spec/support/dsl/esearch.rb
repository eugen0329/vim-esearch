module Support
  module DSL
    module ESearch

      def esearch_settings(options)
        elems = options.map { |name, val| "'#{name}': '#{val}'" }
        dict = "{ #{elems.join(',')} }"

        vim.multiline_command(%{
          if !exists('g:esearch')
            let g:esearch = #{dict}
          else
            call extend(g:esearch, #{dict})
          endif
        })
      end
    end
  end
end
