VimlValue::Types::Funcref = Struct.new(:name) do
  def inspect
    "function(#{name.inspect})"
  end
end
