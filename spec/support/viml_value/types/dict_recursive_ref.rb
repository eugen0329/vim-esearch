# frozen_string_literal: true

class VimlValue::Types::DictRecursiveRef
  def inspect
    '{...}'
  end

  def ==(other)
    self.class == other.class
  end
end
