module Support
  module Vim
    module DSL

      def dump(what)
        if exists('*prettyprint#prettyprint')
          puts expr("prettyprint#prettyprint(#{what})")
        else
          puts expr(what)
        end
      end

      def try_cmd(str)
        cmd("try | #{cmd} | catch | echo v:exception | endtry")
      end

      def expr(str)
        vim.echo(str)
      end

      def press(keys)
        vim.normal(keys)
      end

      def cmd(str)
        begin
          vim.command(str)
        rescue Vimrunner::InvalidCommandError => e
          return e.message
        end
      end

      def bufname(str)
        expr("bufname('#{str}')")
      end

      def line(number)
        expr("getline(#{number})")
      end

      def exists(str)
        expr("exists('#{str}')").to_i != 0
      end

      def has(str)
        expr("has('#{str}')").to_i != 0
      end

    end
  end
end
