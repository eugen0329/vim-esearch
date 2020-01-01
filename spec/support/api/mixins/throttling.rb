# frozen_string_literal: true

module API::Mixins::Throttling
  # Simple implementation of throttling for debug purposes with `sleep()` call
  # if provided time interval is not waited between calls. As it's a part of
  # API, we don't expect concurrent access from multiple threads to a single vim
  # instance, so Mutexes aren't required. It also makes no sense to bundle a
  # gem so far and introduce another dependency for 10 simple lines of code
  def throttle(scope = :global, interval: 1.seconds)
    return yield unless interval.positive?

    Thread.current[:throttling_scopes] ||= {}
    last_call_at = Thread.current[:throttling_scopes][scope]

    if last_call_at
      elapsed_time = Time.now - last_call_at
      sleep(interval - elapsed_time) if elapsed_time < interval
    end

    result = yield
    Thread.current[:throttling_scopes][scope] = Time.now
    result
  end
end
