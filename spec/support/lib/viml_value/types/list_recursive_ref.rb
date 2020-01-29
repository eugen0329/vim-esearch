# frozen_string_literal: true

class VimlValue::Types::ListRecursiveRef
  def inspect
    '[...]'
  end

  def ==(other)
    self.class == other.class
  end
end
