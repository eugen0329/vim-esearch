require "timeout"
require "pty"

require "vimrunner/errors"
require "vimrunner/client"
require "vimrunner/platform"

module Vimrunner
  class NeovimServer
    VIMRC        = Vimrunner::Server::VIMRC
    VIMRUNNER_RC = Vimrunner::Server::VIMRUNNER_RC

    attr_reader :nvr_executable, :vimrc, :gvimrc, :pid, :nvim, :gui, :socket

    def initialize(options = {})
      @nvr_executable = options.fetch(:nvr_executable) { 'nvr' }
      @nvim       = options.fetch(:nvim) { 'nvim' }
      @socket     = options.fetch(:socket) { "/tmp/VIMRUNNER_NEOVIM#{rand}" }
      @vimrc      = options.fetch(:vimrc) { VIMRC }
      @foreground = options.fetch(:foreground, false)
      @gui        = options.fetch(:gui, false)
    end

    def start
      @r, @w, @pid = spawn

      if block_given?
        begin
          @result = yield(connect!)
        ensure
          kill
        end
        @result
      else
        connect!
      end
    end

    def connect(options = {})
      connect!(options)
    rescue TimeoutError
      nil
    end

    def connect!(options = {})
      wait_until_running(options[:timeout] || 5)

      client = new_client
      client.source(VIMRUNNER_RC)
      client
    end

    def running?
      true
      # serverlist.include?(name)
    end

    def kill
      @r&.close
      @w&.close

      begin
        Process.kill(9, @pid)
      rescue Errno::ESRCH
      end

      self
    end

    def new_client
      Client.new(self)
    end

    def serverlist
      execute([nvr_executable, "--serverlist"]).split("\n")
    end

    def remote_expr(expression)
      rval = execute([nvr_executable, '--nostart',  '--servername' ,socket, "--remote-expr", expression])
      remote_send("<C-\\><C-n>jk")
      rval
    end

    def remote_send(keys)
      rval = execute([nvr_executable, '--nostart','--servername' , socket,  "--remote-send", keys.gsub(/<(?![ABCDEFHILMNPRSTUklx])/, '<LT>\1')])
    end

    private

    def execute(command)
      IO.popen(command) { |io| io.read.chomp.gsub(/\A\n/, '') }
    end

    def spawn
      log = ''
      log = '-V9/tmp/vim.log'
      embed = '--embed'
      embed = ''
      # gui = false

      headless = ''
      if gui
        Process.fork { Process.exec(nvim, *%W[--listen #{socket} -n -u #{vimrc} #{embed} #{headless} #{log}]) }; return 1,2,3
      else
        # headless = '--headless'
        return PTY.spawn(nvim, *%W[--listen #{socket} -n -u #{vimrc} #{embed} #{headless} #{log}])
        # return IO.popen([nvim, *%W[--listen #{socket} -n -u #{vimrc} #{embed} #{headless} #{log}]])
      end
    end

    def wait_until_running(seconds)
      sleep 1
      # Timeout.timeout(seconds, TimeoutError) do
      #   sleep 0.1 while !running?
      # end
    end
  end
end
