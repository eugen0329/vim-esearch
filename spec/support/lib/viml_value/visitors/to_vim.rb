# frozen_string_literal: true

class VimlValue::Visitors::ToVim
  CLASS_VISIT_METHODS = {
    Array                          => :visit_array_like,
    Enumerator                     => :visit_array_like,
    Hash                           => :visit_hash,
    Symbol                         => :visit_string_like,
    String                         => :visit_string_like,
    VimlValue::Types::FunctionCall => :visit_function_call,
    VimlValue::Types::Identifier   => :visit_identifier,
    Float                          => :visit_numeric,
    Integer                        => :visit_numeric,
    NilClass                       => :visit_nil
  }.freeze

  def accept(object)
    visit(object)
  end

  private

  def visit(object)
    send(dispatch_cache[object.class], object)
  end

  def visit_array_like(object)
    "[#{object.map { |element| visit(element) }.join(',')}]"
  end

  def visit_hash(object)
    "{#{object.map { |k, v| "#{wrap_in_quotes(k.to_s)}:#{visit(v)}" }.join(',')}}"
  end

  def visit_identifier(object)
    object.string_representation
  end

  def visit_string_like(object)
    wrap_in_quotes(object.to_s).to_s
  end

  def visit_numeric(object)
    object.to_s
  end

  def visit_nil(_object)
    "v:null"
  end

  def visit_function_call(object)
    "#{object.name}(#{visit(object.arguments)[1..-2]})"
  end

  def wrap_in_quotes(str)
    "'#{str.gsub("'", "''")}'"
  end

  def dispatch_cache
    @dispatch_cache ||= Hash.new do |h, klass|
      method = CLASS_VISIT_METHODS.fetch(klass) { h[klass.superclass] }
      raise unless method
      h[klass] = method
    end
  end
end
