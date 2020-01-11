# frozen_string_literal: true

require 'delegate'

class VimrunnerSpy < DecoratorBase
  include CleanCaller

  def self.echo_call_history
    @echo_call_history ||= []
  end

  def self.reset!
    @echo_call_history = []
  end

  def echo(arg)
    result = super(arg)
    __class__.echo_call_history << [arg, result, clean_caller]
    result
  end
end
