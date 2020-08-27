# frozen_string_literal: true

require 'timeout'

module API::Mixins::BecomeTruthyWithinTimeout
  def became_truthy_within?(timeout)
    t0 = Time.now

    loop do
      break true  if yield
      break false if Time.now - t0 > timeout

      sleep 0.1
    end
  end
end
