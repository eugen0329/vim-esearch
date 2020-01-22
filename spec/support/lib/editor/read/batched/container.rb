# frozen_string_literal: true

require 'delegate'

# rubocop:disable Lint/UnderscorePrefixedVariableName
class Editor::Read::Batched::Container < Delegator
  UNDEFINED = ::Object.new.freeze

  attr_reader :__argument__, :__value__

  def initialize(__argument__, __batch__)
    super(UNDEFINED)
    @__argument__ = __argument__
    @__batch__ = __batch__
  end

  def __setobj__(obj)
    @__value__ = obj
  end

  def __getobj__
    __eager__! if @__value__.equal?(UNDEFINED)
    @__value__
  end

  alias __class__ class
  def class
    __getobj__.class
  end

  private

  def __eager__!
    @__batch__.eager!
    remove_instance_variable(:@__batch__)
  end
end
# rubocop:enable Lint/UnderscorePrefixedVariableName
