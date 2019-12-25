require 'timeout'

module API
  module Mixins
    module BecomeTruthyWithinTimeout
      def became_truthy_within?(timeout)
        Timeout.timeout(timeout, Timeout::Error) do
          loop do
            return true if yield

            sleep 0.1
          end
        end
      rescue Timeout::Error
        false
      end
    end
  end
end
