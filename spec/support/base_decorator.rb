require 'delegate'

class BaseDecorator < SimpleDelegator
  def class
    __getobj__.class
  end
end
