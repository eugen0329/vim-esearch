SimpleDelegator


class API::Editor::Read::MagicBatched::Container < BasicObject
  NULL = ::Class.new

  (instance_methods - %i[equal? __id__ __binding__]).each do |method|
    undef_method(method)
  end

  attr_reader :__argument__
  attr_accessor :__value__

  def initialize(__argument__, __batch__)
    @__argument__ = __argument__
    @__batch__ = __batch__
    @__value__    = NULL
  end

  def inspect
    __eager__!
    "<Container of=#{__value__.inspect}>".inspect
  end

  def respond_to_missing?(name, include_private = false)
    return false if name == :marshal_dump || name == :_dump

    __eager__!
    # NOTE: no super for respond_to_missing? in BaseicObject
    __value__.respond_to?(name, include_private)
  end

  def method_missing(method, *args, **kwargs, &block)
    __eager__!
    return super unless __value__.respond_to?(method)
    __value__.public_send(method, *args, **kwargs, &block)
  end

  private

  def __eager__!
    return false if __value__ != NULL

    @__batch__.eager!
    ::Object
      .instance_method(:remove_instance_variable)
      .bind(self)
      .call(:@__batch__)
    true
  end
end
