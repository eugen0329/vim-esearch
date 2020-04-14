# frozen_string_literal: true

require 'pathname'

class VimlValue::Visitors::ToVim
  CLASS_VISIT_METHODS = {
    Enumerable                            => :visit_enumerable,
    Hash                                  => :visit_hash,
    Symbol                                => :visit_string_like,
    String                                => :visit_string_like,
    Pathname                              => :visit_string_like,
    VimlValue::Types::Funcref             => :visit_funcref,
    VimlValue::Types::None                => :visit_none,
    VimlValue::Serializable::FunctionCall => :visit_function_call,
    VimlValue::Serializable::Identifier   => :visit_identifier,
    Numeric                               => :visit_numeric,
    NilClass                              => :visit_nil,
    TrueClass                             => :visit_true,
    FalseClass                            => :visit_false,
  }.freeze

  def accept(object)
    visit(object)
  end

  private

  def visit(object)
    send(dispatch_cache[object.class], object)
  end

  def visit_enumerable(object)
    "[#{visit_values(object)}]"
  end

  def visit_hash(object)
    "{#{object.map { |k, v| "#{visit_string_like(k.to_s)}:#{visit(v)}" }.join(',')}}"
  end

  def visit_identifier(object)
    result = object.to_s
    result += "[#{visit(object.property_access)}]" if object.property_access.present?
    result
  end

  def visit_string_like(object)
    "'#{object.to_s.gsub("'", "''")}'"
  end

  def visit_none(_object)
    'v:none'
  end

  def visit_numeric(object)
    object.to_s
  end

  def visit_nil(_object)
    'v:null'
  end

  def visit_true(_object)
    'v:true'
  end

  def visit_false(_object)
    'v:false'
  end

  def visit_funcref(object)
    args = [visit_string_like(object.name), visit_values(object.args)]
    "function(#{args.join(', ')})"
  end

  def visit_function_call(object)
    result = "#{object.name}(#{visit_values(object.arguments)})"

    result += "[#{visit(object.property_access)}]" if object.property_access.present?
    result
  end

  # Name is choosen to correspond to the non-terminal in parser.y
  def visit_values(object)
    object.map { |element| visit(element) }.join(',')
  end

  def dispatch_cache
    @dispatch_cache ||= Hash.new do |h, klass|
      ancestor = klass.ancestors.find { |a| CLASS_VISIT_METHODS.key?(a) }
      raise TypeError, "don't know how to dump #{klass.name}" unless ancestor

      h[klass] = CLASS_VISIT_METHODS[ancestor]
    end
  end
end
