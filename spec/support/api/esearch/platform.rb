# frozen_string_literal: true

class API::ESearch::Platform
  include API::Mixins::BecomeTruthyWithinTimeout

  class_attribute :process_check_timeout, default: Configuration.process_check_timeout

  def grep_and_kill_process_by!(pattern, signal: 'KILL')
    pids = `ps -A -o pid,command | grep "#{pattern}" | grep -v grep | awk '{print $1}'`.split("\n")

    # as far as POSIX xargs doesn't have -r option
    pids.each do |pid|
      `kill -s #{signal} #{pid}`
    end
  end

  def has_no_process_matching?(command_pattern, timeout: process_check_timeout)
    became_truthy_within?(timeout) do
      # we are not interesting in `ignore_pattern` as in
      # `has_running_processes_matching?` as any process matching
      # `command_pattern` (no matter a perent or a child) have to not be runned
      # or to be killed during the timeout
      processess_matching(command_pattern).blank?
    end
  end

  # TODO: consider to refactor
  def processess_matching(command_pattern, ignore_pattern = nil)
    processes = ps_commands.select { |str| str.include?(command_pattern) }
    processes = processes.reject { |str| str.include?(ignore_pattern) } if ignore_pattern

    processes
  end

  def ps_commands
    `ps -A -o pid,etime,command | sed 1d`.split("\n")
  end
end
