# frozen_string_literal: true

require 'yaml'

class API::Editor::Serialization::Serializer
  class UnknownObjectTypeError < RuntimeError; end

  def serialize(object)
    case object
    when Array, Enumerator
      "[#{object.map { |element| serialize(element) }.join(',')}]"
    when Hash
      "{#{object.map { |k, v| "'#{escape(k)}':#{serialize(v)}" }.join(',')}}"
    when String, Symbol
      "'#{escape(object)}'"
    when Numeric, API::Editor::Serialization::Identifier
      object
    else raise UnknownObjectTypeError, "what is it?? #{object.inspect}"
    end
  end

  private

  def escape(str)
    str.gsub("'", "\\'")
  end
end
