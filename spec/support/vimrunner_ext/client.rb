module Vimrunner
  class Client
    alias_method :command_unpatched, :command

    # Converts multiline commands to vim multiline command expr
    def command(commands)
      send(:command_unpatched, commands.gsub("\n", "<CR>"))
    end
  end
end
