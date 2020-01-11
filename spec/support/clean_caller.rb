# frozen_string_literal: true

require 'active_support/backtrace_cleaner'

module CleanCaller
  BACKTRACE_CLEANER = ActiveSupport::BacktraceCleaner.new.tap do |bc|
    bc.add_filter { |line| line.gsub(Configuration.root.to_s, '') }
  end

  def clean_caller
    BACKTRACE_CLEANER.clean(caller.tap(&:unshift))
  end
end
