# frozen_string_literal: true

RSpec::Matchers.define :have_running_processes_matching do |command_pattern, ignore_pattern, count: 1, timeout: nil|
  include API::Mixins::BecomeTruthyWithinTimeout

  match do |esearch|
    timeout ||= esearch.platform.process_check_timeout

    became_truthy_within?(timeout) do
      esearch.platform.processess_matching(command_pattern, ignore_pattern).count == count
    end
  end

  failure_message do |esearch|
    processes = esearch.platform.processess_matching(command_pattern, ignore_pattern)
    process_description = "running processe(s) matching #{command_pattern} (ignoring #{ignore_pattern})"

    if processes.count == 0
      got = "got #{processes.count}. Other processes list #{esearch.platform.ps_commands.join("\n")}"
    else
      got = "got #{processes.count}:\n#{processes.join("\n")}"
    end

    "expected to have #{count} #{process_description}, #{got}"
  end
end
