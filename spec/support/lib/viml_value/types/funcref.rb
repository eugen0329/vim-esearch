# frozen_string_literal: true

VimlValue::Types::Funcref = Struct.new(:name) do
  def inspect
    "function(#{name.inspect})"
  end

  def pretty_print(q)
    q.text(inspect)
  end
end
