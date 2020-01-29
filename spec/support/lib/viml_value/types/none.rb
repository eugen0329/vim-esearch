# frozen_string_literal: true

class VimlValue::Types::None
  def inspect
    'v:none'
  end

  def pretty_print(pretty_print)
    pretty_print.text('None')
  end

  def ==(other)
    self.class == other.class
  end
end
