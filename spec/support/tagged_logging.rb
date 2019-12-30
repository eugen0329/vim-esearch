# frozen_string_literal: true

# methods are intentionally without positional argument support (like in logger
# methods) to enforce performance
module TaggedLogging
  def class_name_tagged
    Configuration.log.tagged(self.class.to_s) do
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
    class_name_tagged { Configuration.log.warning { yield } }
  end
end
