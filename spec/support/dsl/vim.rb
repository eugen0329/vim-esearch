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

      def try_cmd(str)
        cmd("try | #{cmd} | catch | echo v:exception | endtry")
      end

      def expr(str)
        vim.echo(str)
      end

      #TODO
      def press_output(cmd)
        press(":let g:__redirected_output__ = '_'<Enter>")
        press(":redir => g:__redirected_output__<Enter>")
        press(":try<CR>#{cmd}:catch<CR>:echo 'Error: '.v:exception.' at '.v:throwpoint<CR>:endtry<CR>")
        press(":redir END<CR>")
        expr("g:__redirected_output__")
      end

      def bool_expr(str)
        vim.echo(str).to_i == 1
      end

      def press(keys)
        vim.normal(keys)
      end

      def cmd(str)
        max_retries = 2
        cb = ->(e) {  puts "WARNING: #{e.message}" }
        on = [Vimrunner::InvalidCommandError]

        Retryable.retryable(tries: max_retries, sleep: 1, on: on, exception_cb: cb) do
          return vim.command(str)
        end
      end

      def bufname(str)
        expr("bufname('#{str}')")
      end

      def line(number)
        expr("getline(#{number})")
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
