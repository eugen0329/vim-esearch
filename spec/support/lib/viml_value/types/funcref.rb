# frozen_string_literal: true

VimlValue::Types::Funcref = Struct.new(:name) do
  def inspect
    "function(#{name.inspect})"
  end

  def pretty_print(pretty_print)
    pretty_print.text(inspect)
  end
end
