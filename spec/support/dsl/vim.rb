# frozen_string_literal: true

module Support
  module DSL
    module Vim
      def dump(what)
        # if exists('*prettyprint#prettyprint')
        puts expr("prettyprint#prettyprint(#{what})")
        # else
        #   puts expr(what)
        # end
      end

      def try_cmd(_str)
        cmd("try | #{cmd} | catch | echo v:exception | endtry")
      end

      def expr(str)
        vim.echo(str)
      end

      # TODO
      def output(keys)
        vim.multiline_command(%{
          if exists('g:__redirected_output__')
            unlet g:__redirected_output__
          endif
          let g:__redirected_output__ = '_'
        })
        press(':redir => g:__redirected_output__<CR>')
        type(':try<CR>')
        type(keys)
        type(":catch<CR>:echo 'Error: '.v:exception.' at '.v:throwpoint<CR>:endtry<CR>")
        press(':redir END<CR>')
        expr('g:__redirected_output__')
      end

      def bool_expr(str)
        vim.echo(str).to_i == 1
      end

      def press(keys)
        vim.normal(keys)
      end

      def press_with_respecting_mappings(keys)
        vim.feedkeys(keys)
      end

      def type(keys)
        vim.type(keys)
      end

      def cmd(str)
        vim.command(str)
      end

      def bufname(str)
        expr("bufname('#{str}')")
      end

      def line(number)
        expr("getline(#{number})")
      end

      def lines
        (1..expr("line('$')").to_i).map do |line_number|
          expr("getline(#{line_number})")
        end
      end

      def buffer_content
        lines.join("\n")
      end

      def exists(str)
        expr("exists('#{str}')").to_i == 1
      end

      def has(str)
        expr("has('#{str}')").to_i == 1
      end
    end
  end
end
