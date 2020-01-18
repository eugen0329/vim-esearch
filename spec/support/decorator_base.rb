# frozen_string_literal: true

require 'delegate'

class DecoratorBase < SimpleDelegator
  alias __class__ class
  def class
    __getobj__.class
  end
end
