RSpec::Matchers.define :become_true_within do |expected|
  supports_block_expectations

  match do |actual|
    return !!actual unless actual.is_a? Proc

    quota = Time.now + expected
    loop do
      return true if actual.call
      break if Time.now >= quota
      sleep 0.5
    end

    false
  end

  failure_message do |actual|
    "expected that expr would become true within #{expected} seconds"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not become true within #{expected} seconds"
  end

  description do
   "become true within #{expected} seconds"
  end
end
