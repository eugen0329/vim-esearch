# frozen_string_literal: true

module TaggedLogging
  def tag_with_classname
    Configuration.log.tagged([self.class.to_s, object_id].join(':')) do
      yield
    end
  end

  def log_debug
    tag_with_classname { Configuration.log.debug { yield } }
  end

  def log_info
    tag_with_classname { Configuration.log.info { yield } }
  end

  def log_warning
    tag_with_classname { Configuration.log.warn { yield } }
  end
end
