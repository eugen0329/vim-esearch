# frozen_string_literal: true

class API::Editor::Read::Batched < API::Editor::Read::Base
  include TaggedLogging

  Placeholder = Struct.new(:identifier, :value) do
    NULL = Class.new

    def initialize(identifier, value = NULL)
      super
    end

    def empty?
      value == NULL
    end
  end

  attr_reader :cache, :cache_enabled

  def initialize(read_proxy, vim_client_getter, cache_enabled)
    super(read_proxy, vim_client_getter)
    @cache_enabled = cache_enabled
    @cache = CacheStore.new
  end

  def echo(argument = nil)
    return argument if @echo_return_unevaluated
    return cache.fetch(argument) if cache_exist?(argument)

    shape, batch = constructor.accept(argument)
    batch = batch
      .lookup!(cache)
      .evaluate! { |identifiers| deserialize(vim.echo(serialize(identifiers))) }
      .write(cache)
    evaluated_argument = reconstrucor.accept(shape, batch)
    cache.write(argument, evaluated_argument) unless cache.exist?(argument)

    evaluated_argument
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

  def batch_echo(&block)
    return yield if Configuration.version != 3

    # raise ArgumentError unless [argument, block].count(&:present?) == 1
    begin
      @echo_return_unevaluated = true
      batch_arg = read_proxy.yield_self(&block)
    ensure
      @echo_return_unevaluated = false
    end

    echo(batch_arg)
  end

  private

  def reconstrucor
    @reconstrucor ||= API::Editor::Read::Batched::ReconstructVisitor.new(self)
  end

  def constructor
    @constructor ||= API::Editor::Read::Batched::ConstructVisitor.new(self)
  end
end
