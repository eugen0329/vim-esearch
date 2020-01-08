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
#   [object.line(1), object.line(2)]                   # => 2 calls
#   reader.echo { [line(1), line(2), line(3)] }       # => 1 call
#   reader.echo { {first: line(1), second: line(2)} } # => 1 call

class API::Editor::Read::Batch < API::Editor::Read::Base
  include TaggedLogging

  delegate :serialize, to: :serializer
  delegate :deserialize, to: :deserializer

  attr_reader :cache, :cache_enabled

  def initialize(read_proxy, vim_client_getter, cache_enabled)
    super(read_proxy, vim_client_getter)
    @cache_enabled = cache_enabled
    @cache = CacheStore.new
  end

  def echo(arg = nil, &block)
    cached(:echo, arg, block) do
      batch_arg = block_given? ? read_proxy.yield_self(&block) : arg

      deserialize(vim.echo(serialize(batch_arg)))
    end
  end

  def cached(*args)
    return yield if @with_ignore_cache || !cache_enabled

    @cache.fetch([*args]) { yield }
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
end
