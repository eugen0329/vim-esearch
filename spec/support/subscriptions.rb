# frozen_string_literal: true

require 'active_support/notifications'

LOG_TAG_PADDING = 15

ActiveSupport::Notifications.subscribe(/cache_read/) do |_name, _start, _finish, _id, payload|
  Configuration.log.tagged('cache.read'.rjust(LOG_TAG_PADDING)) do
    Configuration.log.debug { (payload[:key]).to_s }
  end
end

ActiveSupport::Notifications.subscribe(/cache_clear/) do |_name, _start, _finish, _id, payload|
  Configuration.log.tagged('cache.clear'.rjust(LOG_TAG_PADDING)) do
    Configuration.log.debug { "CLEAR #{payload[:object_id]}" }
  end
end

ActiveSupport::Notifications.subscribe(/cache_write_value/) do |_name, _start, _finish, _id, payload|
  Configuration.log.tagged('cache.write'.rjust(LOG_TAG_PADDING)) do
    Configuration.log.debug do
      echos =
        if Configuration.debug_specs_performance?
          VimrunnerSpy.echo_call_history.count
        else
          'n/a'
        end

      "#{payload[:key]} := #{payload[:value]} (echos: #{echos})"
    end
  end
end

ActiveSupport::Notifications.subscribe(/\Aeditor\./) do |name, _start, _finish, _id, payload|
  Configuration.log.tagged(name.rjust(LOG_TAG_PADDING)) do
    Configuration.log.debug { (payload[:data]).to_s }
  end
end
