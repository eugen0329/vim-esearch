class API::Editor::Read::MagicBatched::Container < BasicObject
  NULL = ::Class.new

  (instance_methods - %i[equal? __id__ __binding__]).each do |method|
    undef_method(method)
  end

  attr_reader :__argument__
  attr_accessor :__value__

  def initialize(__argument__)
    @__argument__ = __argument__
    @__value__    = NULL
    __push_self_into_batch__!
  end

  def inspect
    __eager__!
    "<Container of=#{__value__.inspect}>".inspect
  end

  def to_s
    __eager__!
    __value__.to_s
  end

  def respond_to_missing?(name, _include_private = false)
    return false if name == :marshal_dump || name == :_dump

    __eager__!
    # we don't pass include_private to avoid delegation to private methods
    __value__.respond_to?(name) # NOTE: no super for respond_to_missing? in BaseicObject
  end

  def method_missing(method, *args, **kwargs, &block)
    __eager__!
    if __value__.respond_to?(method)
      __value__.public_send(method, *args, **kwargs, &block)
    else
      super
    end
  end

  private

  def __eager__!
    return true if __value__ != NULL

    ::API::Editor::Read::MagicBatched.evaluate_batch!
  end

  def __push_self_into_batch__!
    ::API::Editor::Read::MagicBatched::Batch.current.push(self)
  end
end
