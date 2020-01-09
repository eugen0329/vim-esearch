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

  def batch_echo(&block)
    return yield if Configuration.version != 3

    begin
      @echo_return_unevaluated = true
      batch_arg = read_proxy.yield_self(&block)
    ensure
      @echo_return_unevaluated = false
    end

    echo(batch_arg)
  end

  def echo(arg = nil, &block)
    return arg if @echo_return_unevaluated
    raise ArgumentError unless [arg, block].count(&:present?) == 1


    return cached([:echo, arg]) if cache_exist?([:echo, arg])

    result = begin

      shape, batch, placeholders = constructor.accept(arg)
      evaluated_batch = deserialize(vim.echo(serialize(batch)))
      reconstructed = reconstrucor.accept(shape, evaluated_batch)

      cache.write([:echo, arg], reconstructed)

      #       log_debug do
      #         cached_args = [arg].flatten.select { |arg| self.cache.exist?(arg) }
      #         cached_results = cached_args.map { |arg| self.cache.fetch(arg) }
      #         "1. cached_args: #{cached_args.map(&:to_s).zip(cached_results).to_h}"
      #       end
      log_debug { "new_args: #{batch.zip(evaluated_batch).to_h} #{VimrunnerSpy.echo_call_history.size}" }

      reconstructed
    end

    result
  end

  def with_ignore_cache
    @with_ignore_cache = true
    yield
  ensure
    @with_ignore_cache = false
  end

  def clear_cache
    return if @with_ignore_cache || !cache_enabled

    cache.clear
  end

  def cached(key, &block)
    return block&.call if @with_ignore_cache || !cache_enabled

    cache.fetch(key, &block)
  end

  def cache_exist?(key)
    return false if @with_ignore_cache || !cache_enabled

    cache.exist? key
  end

  private

  def reconstrucor
    @reconstrucor ||= API::Editor::Read::ReconstructVisitor.new(self)
  end

  def constructor
    @constructor ||= API::Editor::Read::FlatBatchVisitor.new(self)
  end
end
