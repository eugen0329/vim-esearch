# frozen_string_literal: true

# Usage:
#   object = OpenStruct.new.tap do |o|
#     def o.line(number)
#       reader.echo(reader.func("line(#{number})"))
#     end
#   end
#
#   object.reader = Batch.new(object, ...)
#
# [object.line(1), object.line(2)]                          # => 2 calls
# reader.echo { |o| [e.line(1), o.line(2), o.line(3)] }     # => 1 call
# reader.echo { |o| {first: o.line(1), second: o.line(2)} } # => 1 call

class API::Editor::Read::Batch < API::Editor::Read::Base
  include TaggedLogging

  Placeholder = Struct.new(:offset, :identifier)

  delegate :serialize,   to: :serializer
  delegate :deserialize, to: :deserializer

  attr_reader :cache, :cache_enabled

  def initialize(read_proxy, vim_client_getter, cache_enabled)
    super(read_proxy, vim_client_getter)
    @cache_enabled = cache_enabled
    @cache = CacheStore.new
  end

  def echo(arg = nil, &block)
    return arg if @collect_for_batch
    raise ArgumentError unless [arg, block].count(&:present?) == 1

    batch_arg =
      if block.present?
        begin
          @collect_for_batch = true
          read_proxy.yield_self(&block)
        ensure
          @collect_for_batch = false
        end
      else
        arg
      end

    result = cached([:echo, batch_arg]) do
      shape, flat_batch = construct(batch_arg)
      evaluated_batch = deserialize(vim.echo(serialize(flat_batch)))
      reconstruct(shape, evaluated_batch)
    end

    result
  end

  # TODO: extract visitors code

  def reconstruct(shape, evaluated_batch)
    case shape
    when Array then reconstruct_from_array(shape, evaluated_batch)
    when Hash then reconstruct_from_hash(shape, evaluated_batch)
    when Placeholder then reconstruct_from_placeholder(shape, evaluated_batch)
    else shape
    end
  end

  def construct(arg, flat_batch = [])
    case arg
    when Array then construct_from_array(arg, flat_batch)
    when Hash then construct_from_hash(arg, flat_batch)
    when API::Editor::Serialization::Identifier then construct_from_identifier(arg, flat_batch)
    else [arg, flat_batch]
    end
  end

  def reconstruct_from_placeholder(placeholder, evaluated_batch)
    cached([:echo, placeholder.identifier]) do
      evaluated_batch[placeholder.offset]
    end
  end

  def reconstruct_from_hash(shape, evaluated_batch)
    shape.map do |key, value|
      reconstructed_value = reconstruct(value, evaluated_batch)
      [key, reconstructed_value]
    end.to_h
  end

  def reconstruct_from_array(shape, evaluated_batch)
    shape.map { |value| reconstruct(value, evaluated_batch) }
  end

  def construct_from_identifier(identifier, flat_batch)
    key = [:echo, identifier]
    return [cached(key), flat_batch] if cache_exists?(key)

    flat_batch = flat_batch.dup
    flat_batch << identifier
    [Placeholder.new(flat_batch.count - 1, identifier), flat_batch]
  end

  def construct_from_array(array, flat_batch)
    flat_batch = flat_batch.dup

    shape = array.map do |value|
      shape, flat_batch = construct(value, flat_batch)
      shape
    end

    [shape, flat_batch]
  end

  def construct_from_hash(hash, flat_batch)
    flat_batch = flat_batch.dup

    shape = hash.map do |key, value|
      shape, flat_batch = construct(value, flat_batch)

      [key, shape]
    end.to_h

    [shape, flat_batch]
  end

  def with_ignore_cache
    @with_ignore_cache = true
    yield
  ensure
    @with_ignore_cache = false
  end

  def clear_cache
    return if @with_ignore_cache || !cache_enabled

    @cache.clear
  end

  private

  def cached(key, &block)
    return block&.call if @with_ignore_cache || !cache_enabled

    @cache.fetch(key, &block)
  end

  def cache_exists?(key)
    return false if @with_ignore_cache || !cache_enabled

    @cache.exists? key
  end
end
