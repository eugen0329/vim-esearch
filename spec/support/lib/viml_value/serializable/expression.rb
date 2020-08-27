# frozen_string_literal: true

# Base class for serializable values
class VimlValue::Serializable::Expression
  attr_reader :property_access

  def [](property_access)
    @property_access = property_access
    self
  end
end
