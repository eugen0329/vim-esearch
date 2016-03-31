module Vimrunner
  class Client

    def multiline_command(commands)
      converted = commands.sub(/(\n\s*)+$/, '').sub(/^(\s*\n)+/, '').gsub("\n", '<CR>')
      send(:command, converted)
    end
  end
end
