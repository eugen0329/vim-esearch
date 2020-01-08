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

class API::ESearch::Editor::Read::Base
  delegate :serialize, to: :serializer
  delegate :deserialize, to: :deserializer

  attr_reader :vim_client_getter, :read_proxy

  def initialize(read_proxy, vim_client_getter)
    @vim_client_getter       = vim_client_getter
    @read_proxy              = read_proxy
  end

  def id(string_representation)
    API::ESearch::Editor::Serialization::Identifier.new(string_representation)
  end
  alias var  id
  alias func id

  private

  def vim
    vim_client_getter.call
  end

  def serializer
    @serializer ||= API::ESearch::Editor::Serialization::Serializer.new
  end

  def deserializer
    @deserializer ||= API::ESearch::Editor::Serialization::Deserializer.new
  end
end
