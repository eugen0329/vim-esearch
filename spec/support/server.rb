class Server < DecoratorBase
  def self.vim(...)
    new(Vimrunner::Server.new(...))
  end

  def self.neovim(...)
    new(VimrunnerNeovim::Server.new(...))
  end
  # def new_client
  #   Client.new(__getobj__)
  # end
end
