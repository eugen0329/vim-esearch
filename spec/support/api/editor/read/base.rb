# frozen_string_literal: true

class API::Editor::Read::Base
  include API::Editor::Serialization::Helpers
  delegate :serialize, to: :serializer
  delegate :deserialize, to: :deserializer

  attr_reader :vim_client_getter, :read_proxy

  def initialize(read_proxy, vim_client_getter)
    @vim_client_getter       = vim_client_getter
    @read_proxy              = read_proxy
  end

  def cache
    raise NotImplementedError
  end

  def cached?
    raise NotImplementedError
  end

  def with_ignore_cache
    raise NotImplementedError
  end

  def evaluated?
    raise NotImplementedError
  end

  private

  def vim
    vim_client_getter.call
  end

  def serializer
    @serializer ||= API::Editor::Serialization::Serializer.new
  end

  def deserializer
    @deserializer ||= API::Editor::Serialization::YAMLDeserializer.new
  end
end
