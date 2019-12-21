require "timeout"
require "pty"

require "vimrunner/errors"
require "vimrunner/client"
require "vimrunner/platform"

module VimrunnerNeovim
  class Server
    VIMRC        = Vimrunner::Server::VIMRC
    VIMRUNNER_RC = Vimrunner::Server::VIMRUNNER_RC

    attr_reader :nvr_executable, :vimrc, :gvimrc, :pid, :nvim, :gui, :name, :logfile

    def initialize(options = {})
      @nvr_executable = options.fetch(:nvr_executable) { 'nvr' }
      @name           = options.fetch(:name) { "/tmp/VIMRUNNER_NEOVIM#{Time.now.to_i}" }
      @logfile        = options.fetch(:logfile) { '/tmp/vimrunner_neovim.log' }
      @nvim           = options.fetch(:nvim) { 'nvim' }
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


      # >= 1	When the shada file is read or written.
      # >= 2	When a file is ":source"'ed.
      # >= 3	UI info, terminal capabilities
      # >= 5	Every searched tags file and include file.
      # >= 8	Files for which a group of autocommands is executed.
      # >= 9	Every executed autocommand.
      # >= 12	Every executed function.
      # >= 13	When an exception is thrown, caught, finished, or discarded.
      # >= 14	Anything pending in a ":finally" clause.
      # >= 15	Every executed Ex command (truncated at 200 characters).
      verbose_level = 15
      log = "-V#{verbose_level}#{logfile}"
      embed = ''

      headless = ''
      if gui
        pid = Process.fork { Process.exec(nvim, *%W[--listen #{name} -n -u #{vimrc} #{embed} #{headless} #{log}]) }
        [nil, nil, pid]
      else
        headless = '--headless'
        return IO.popen([nvim, *%W[--listen #{name} -n -u #{vimrc} #{embed} #{headless} #{log}]])
        # return PTY.spawn(nvim, *%W[--listen #{name} -n -u #{vimrc} #{embed} #{headless} #{log}])
        pid = Process.fork { Process.exec(nvim, *%W[--listen #{name} -n -u #{vimrc} #{embed} #{headless} #{log}]) }
        [nil, nil, pid]
      end
    end

    def wait_until_running(seconds)
      Timeout.timeout(seconds, Timeout::Error) do
        sleep 0.1 while !running?
      end
    end
  end
end
