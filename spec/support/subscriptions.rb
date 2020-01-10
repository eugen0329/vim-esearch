require 'active_support/notifications'

def padded(str)
  format '%15s', str
end

ActiveSupport::Notifications.subscribe(/cache_read/) do |name, start, finish, id, payload|
  Configuration.log.tagged(padded('cache.read')) do
    Configuration.log.debug { "#{payload[:key]}" }
  end
end

ActiveSupport::Notifications.subscribe(/cache_write_value/) do |name, start, finish, id, payload|
  Configuration.log.tagged(padded('cache.write')) do
    Configuration.log.debug do
      echos = if  Configuration.debug_specs_performance?
        VimrunnerSpy.echo_call_history.count
      else
        'n/a'
      end

      "#{payload[:key]} := #{payload[:value]} (echos: #{echos})"
    end
  end
end

ActiveSupport::Notifications.subscribe(/\Aeditor\./) do |name, start, finish, id, payload|
  Configuration.log.tagged(padded(name)) do
    Configuration.log.debug { "#{payload[:data]}" }
  end
end
