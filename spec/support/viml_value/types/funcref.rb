# frozen_string_literal: true

VimlValue::Types::Funcref = Struct.new(:name, :args) do
  def initialize(name, *args)
    super(name, args)
  end

  def inspect
    "function(#{[name.inspect, *args.map(&:inspect)].join(', ')})"
  end

  def pretty_print(pretty_print)
    pretty_print.text(inspect)
  end
end
