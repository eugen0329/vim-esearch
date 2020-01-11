# frozen_string_literal: true

require 'active_support/backtrace_cleaner'

# methods are intentionally without positional argument support (like in logger
# methods) to enforce performance
module TaggedLogging
  BC = ActiveSupport::BacktraceCleaner.new.tap do |bc|
    bc.add_filter { |line| line.gsub(Configuration.root.to_s, '') }
  end

  def class_name_tagged
    Configuration.log.tagged([self.class.to_s, object_id].join('-')) do
      yield
    end
  end

  def log_debug
    class_name_tagged { Configuration.log.debug { yield } }
  end

  def log_info
    class_name_tagged { Configuration.log.info { yield } }
  end

  def log_warning
    class_name_tagged { Configuration.log.warn { yield } }
  end

  def clean_caller
    BC.clean(caller)
    # .reject { |l| l.include?('tagged_logging') }
    # .select { |l| l.to_s.start_with?(Configuration.root.to_s) }
    # .tap(&:shift)
  end
end
