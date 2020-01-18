# frozen_string_literal: true

require 'yaml'

class Editor::Serialization::Serializer
  class UnknownSerializer < RuntimeError; end

  CLASS_TO_SERIALIZER = {
    Array                                    => :serialize_array_like,
    Enumerator                               => :serialize_array_like,
    Hash                                     => :serialize_hash,
    Symbol                                   => :serialize_string_like,
    String                                   => :serialize_string_like,
    Editor::Serialization::FunctionCall => :serialize_function_call,
    Editor::Serialization::Identifier   => :serialize_identifier,
    Float                                    => :serialize_numberic,
    Integer                                  => :serialize_numberic,
    NilClass                                 => :serialize_nil
  }.freeze

  def serialize(object)
    public_send(CLASS_TO_SERIALIZER.fetch(object.class), object)
  rescue KeyError
    raise UnknownSerializer, "what is it?? #{object.inspect}"
  end

  def serialize_array_like(object)
    "[#{object.map { |element| serialize(element) }.join(',')}]"
  end

  def serialize_hash(object)
    "{#{object.map { |k, v| "#{wrap_in_quotes(k.to_s)}:#{serialize(v)}" }.join(',')}}"
  end

  def serialize_identifier(object)
    object.string_representation
  end

  def serialize_string_like(object)
    wrap_in_quotes(object.to_s).to_s
  end

  def serialize_numberic(object)
    object.to_s
  end

  def serialize_nil(_object)
    "''"
  end

  def serialize_function_call(object)
    "#{object.name}(#{serialize(object.arguments)[1..-2]})"
  end

  def wrap_in_quotes(str)
    "'#{str.gsub("'", "''")}'"
  end
end
