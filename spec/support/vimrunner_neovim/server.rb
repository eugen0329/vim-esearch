# frozen_string_literal: true

require 'timeout'
require 'pty'
require 'open3'

require 'vimrunner/errors'
require 'vimrunner/client'
require 'vimrunner/platform'

require 'active_support/core_ext/class/attribute'

# rubocop:disable Layout/ClassLength
module VimrunnerNeovim
  class Server
    VIMRC        = Vimrunner::Server::VIMRC
    VIMRUNNER_RC = Vimrunner::Server::VIMRUNNER_RC
    REMOTE_EXPR_METHOD_NAMES = {
      prepend_with_escape_press:                        :remote_expr_prepended_with_escape_press,
      fallback_to_prepend_with_escape_press_on_timeout: :remote_expr_with_fallback_on_timeout,
      default:                                          :remote_expr_default
    }.freeze
    class_attribute :remote_expr_execution_mode,
                    default: :prepend_with_escape_press
    class_attribute :remote_expr_execution_timeout,
                    default: 0.5.seconds

    attr_reader :nvr_executable, :vimrc, :nvim, :gui, :name,
      :verbose_level, :verbose_log_file, :nvim_log_file

    def initialize(options = {})
      @nvr_executable = options.fetch(:nvr_executable) { 'nvr' }
      @name           = options.fetch(:name) { "/tmp/VIMRUNNER_NEOVIM#{Time.now.to_i}" }
      @nvim           = options.fetch(:nvim) { 'nvim' }
      @vimrc          = options.fetch(:vimrc) { VIMRC }
      @foreground     = options.fetch(:foreground, false)
      @gui            = options.fetch(:gui, false)

      # >= 1  When the shada file is read or written.
      # >= 2  When a file is ":source"'ed.
      # >= 3  UI info, terminal capabilities
      # >= 5  Every searched tags file and include file.
      # >= 8  Files for which a group of autocommands is executed.
      # >= 9  Every executed autocommand.
      # >= 12  Every executed function.
      # >= 13  When an exception is thrown, caught, finished, or discarded.
      # >= 14  Anything pending in a ":finally" clause.
      # >= 15  Every executed Ex command (truncated at 200 characters).
      @verbose_level    = options.fetch(:verbose_level, 0)
      @verbose_log_file = options.fetch(:verbose_log_file) { '/tmp/vimrunner_neovim_verbose_log.log' }

      # $NVIM_LOG_FILE variable for nvim
      @nvim_log_file = options.fetch(:nvim_log_file) { "#{Dir.home}/.local/share/nvim/log" }
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
      puts 'Timeout' * 10
      nil
    end

    def connect!(options = {})
      wait_until_running(options[:timeout] || 5)

      client = new_client
      client.source(VIMRUNNER_RC)
      client
    end

    def running?
      serverlist.include?(name) && File.socket?(name) && alive?
    end

    def alive?
      !!Process.kill(0, @pid)
    rescue StandardError
      false
    end

    def kill
      @r&.close
      @w&.close

      begin
        Process.kill(9, @pid)
        Process.wait
      rescue Errno::EPERM
        puts "Errno::EPERM (not permitted) #{@pid}"
      rescue Errno::ESRCH
        puts "Errno::ESRCH (no shuch process) #{@pid}"
      end
      self
    end

    def new_client
      Vimrunner::Client.new(self)
    end

    def serverlist
      execute([nvr_executable, '--serverlist']).split("\n")
    end

    def remote_expr(expression)
      method_name = REMOTE_EXPR_METHOD_NAMES.fetch(remote_expr_execution_mode) do
        raise "Unknown execution mode remote_expr_execution_mode: #{remote_expr_execution_mode}"
      end

      public_send(method_name, expression)
    end

    def remote_expr_default(expression)
      execute([nvr_executable, *nvr_args, '--remote-expr', expression])
    end

    def remote_expr_with_fallback_on_timeout(expression)
      args = [nvr_executable, *nvr_args, '--remote-expr', expression, '-s']
      result = nil
      Timeout.timeout(remote_expr_execution_timeout, Timeout::Error) do
        Thread.abort_on_exception = true
        thread = Thread.new { result = execute(args) }
        thread.abort_on_exception = true
        thread.join
      end
      result
    rescue Timeout::Error
      remote_expr_prepended_with_escape_press(expression)
      # ensure
      # Thread.abort_on_exception = false
    end

    def remote_expr_prepended_with_escape_press(expression)
      remote_send('<C-\\><C-n><Esc>')
      remote_expr_default(expression)
    end

    def remote_send(keys)
      execute([nvr_executable, *nvr_args, '--remote-send', keys.gsub(/<(?![ABCDEFHILMNPRSTUklx])/, '<LT>\1')])
    end

    private

    def execute(command)
      IO.popen(command) { |io| io.read.chomp.gsub(/\A\n/, '') }
    end

    def spawn
      if gui
        fork_gui
      else
        headless_process_without_extra_output
        # return headless_process_with_extra_output
        # return fork_gui
        # return with_io_popen
        # return background_pty
      end
    end

    def env
      {
        'NVIM_LOG_FILE' => nvim_log_file
      }
    end

    # has problems with io
    def with_io_popen
      pipe = IO.popen([env, nvim, *nvim_args])
      [nil, nil, pipe.pid]
    end

    # hangs forever on linux machines
    def background_pty
      PTY.spawn(env, nvim, '--headless', *nvim_args)
    end

    # doesn't work with pry, but may be ok for CI
    def headless_process_without_extra_output
      pid = fork { exec(env, nvim, *nvim_args, '--embed', '--headless') }
      [nil, nil, pid]
    end

    # Has redundant output with information on what keys was pressed and "Press
    # ENTER or type command to continue". Can be convenient for debug headless
    # mode, but it pollutes output with this messages
    def headless_process_with_extra_output
      pid = fork { exec(env, nvim, *nvim_args) }
      [nil, nil, pid]
    end

    def fork_gui
      exec_nvim_command = "#{nvim} #{nvim_args.join(' ')}"
      # TODO: extract platform check
      pid = if RbConfig::CONFIG['host_os'] =~ /darwin/
              fork { exec(env, 'iterm', exec_nvim_command) }
            else
              # fork { exec(env, 'xterm', '-geometry', '500x20+1000+1', '-e', exec_nvim_command) }
              fork { exec(env, 'xterm', '-e', exec_nvim_command) }
            end
      [nil, nil, pid]
    end

    def nvim_args
      @nvim_args ||= ['--listen', name, '-n', '-u', vimrc, verbose_log_argument, '-c "set nomore"']
    end

    def nvr_args
      @nvr_args ||= ['--nostart', '--servername', name]
    end

    def wait_until_running(seconds)
      Timeout.timeout(seconds, Timeout::Error) { sleep 0.1 until running? }
    end

    def verbose_log_argument
      return '' if verbose_level < 1

      "-V#{verbose_level}#{verbose_log_file}"
    end
  end
end
# rubocop:enable Layout/ClassLength
