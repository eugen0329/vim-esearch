module Vimrunner
  class Client

    def multiline_command(commands)
      send(:command, commands.gsub("\n", '|'))
    end
  end
end
