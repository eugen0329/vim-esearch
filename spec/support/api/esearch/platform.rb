# frozen_string_literal: true

class API::ESearch::Platform
  include API::Mixins::BecomeTruthyWithinTimeout

  class_attribute :process_check_timeout, default: Configuration.process_check_timeout

  def grep_and_kill_process_by!(pattern, signal: 'KILL')
    `ps -A -o pid,command | grep "#{pattern}" | grep -v grep | awk '{print $1}' | xargs kill -s #{signal}`
  end

  def has_no_process_matching?(command_pattern, timeout: process_check_timeout)
    command_regexp = /#{Regexp.quote(command_pattern)}/

    became_truthy_within?(timeout) do
      # we a not interesting in `ignore_pattern` as in
      # `has_running_processes_matching?` as any process matching
      # `command_pattern` (no matter a perent or a child) have to not be runned
      # or to be killed during the timeout
      ps_commands.scan(command_regexp).empty?
    end
  end

  def has_running_processes_matching?(command_pattern, ignore_pattern, count: 1, timeout: process_check_timeout)
    command_regexp = /#{Regexp.quote(command_pattern)}/

    became_truthy_within?(timeout) do
      ps_commands_ignoring(ignore_pattern)
        .scan(command_regexp)
        .count == count
    end
  end

  def ps_commands
    `ps -A -o command | sed 1d`
  end

  def ps_commands_ignoring(ignore_pattern)
    ignore_regexp = /#{Regexp.quote(ignore_pattern)}/

    ps_commands
      .split("\n")
      .reject! { |l| ignore_regexp.match?(l) }
      .join("\n")
  end
end
