class Server < DecoratorBase
  def self.vim(...)
    new(Vimrunner::Server.new(...))
  end

  def self.neovim(...)
    new(VimrunnerNeovim::Server.new(...))
  end

  def connect
    Client.new(__getobj__.connect)
  end
end
