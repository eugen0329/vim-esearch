require "timeout"
require "pty"

require "vimrunner/errors"
require "vimrunner/client"
require "vimrunner/platform"

module VimrunnerNeovim
  class Server
    VIMRC        = Vimrunner::Server::VIMRC
    VIMRUNNER_RC = Vimrunner::Server::VIMRUNNER_RC

    attr_reader :nvr_executable, :vimrc, :gvimrc, :pid, :nvim, :gui, :name

    def initialize(options = {})
      @nvr_executable = options.fetch(:nvr_executable) { 'nvr' }
      @nvim           = options.fetch(:nvim) { 'nvim' }
      @name           = options.fetch(:name) { "/tmp/VIMRUNNER_NEOVIM#{Time.now.to_i}" }
      @vimrc          = options.fetch(:vimrc) { VIMRC }
      @foreground     = options.fetch(:foreground, false)
      @gui            = options.fetch(:gui, false)
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
    rescue Timeout::Error
      puts "Timeout" * 10
      nil
    end

    def connect!(options = {})
      wait_until_running(options[:timeout] || 5)

      client = new_client
      client.source(VIMRUNNER_RC)
      client
    end

    def running?
      serverlist.include?(name) && File.socket?(name)
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
      Vimrunner::Client.new(self)
    end

    def serverlist
      execute([nvr_executable, "--serverlist"]).split("\n")
    end

    def remote_expr(expression)
      rval = execute([nvr_executable, '--nostart',  '--servername' ,name, "--remote-expr", expression])
      remote_send("<C-\\><C-n>jk")
      rval
    end

    def remote_send(keys)
      rval = execute([nvr_executable, '--nostart','--servername' , name,  "--remote-send", keys.gsub(/<(?![ABCDEFHILMNPRSTUklx])/, '<LT>\1')])
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
        pid = Process.fork { Process.exec(nvim, *%W[--listen #{name} -n -u #{vimrc} #{embed} #{headless} #{log}]) }
        [nil, nil, pid]
      else
        # headless = '--headless'
        PTY.spawn(nvim, *%W[--listen #{name} -n -u #{vimrc} #{embed} #{headless} #{log}])
        # return IO.popen([nvim, *%W[--listen #{name} -n -u #{vimrc} #{embed} #{headless} #{log}]])
      end
    end

    def wait_until_running(seconds)
      Timeout.timeout(seconds, Timeout::Error) do
        sleep 0.1 while !running?
      end
    end
  end
end
