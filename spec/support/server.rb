# frozen_string_literal: true

class Server < DecoratorBase
  def self.vim(...)
    new(Vimrunner::Server.new(...))
  end

  def self.neovim(...)
    new(VimrunnerNeovim::Server.new(...))
  end
end
