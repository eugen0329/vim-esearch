# frozen_string_literal: true

require 'yaml'

class API::Editor::Serialization::Serializer
  class UnknownObjectTypeError < RuntimeError; end

  def serialize(object)
    case object
    when Array, Enumerator
      "[#{object.map { |element| serialize(element) }.join(',')}]"
    when Hash
      "{#{object.map { |k, v| "#{wrap_in_quotes(k.to_s)}:#{serialize(v)}" }.join(',')}}"
    when String, Symbol
      "#{wrap_in_quotes(object.to_s)}"
    when API::Editor::Serialization::FunctionCall
      "#{object.name}(#{serialize(object.arguments)[1..-2]})"
    when Numeric, NilClass, API::Editor::Serialization::Identifier
      object
    else raise UnknownObjectTypeError, "what is it?? #{object.inspect}"
    end
  end

  private

  def wrap_in_quotes(str)
    "'#{str.gsub("'", "''")}'"
  end
end
