# frozen_string_literal: true

module API::Mixins::VimTypes
  def to_vim_dict(hash)
    pairs = hash.map do |key, value|
      value = to_vim_type(value)
      "'#{key}':#{value}"
    end
    "{#{pairs.join(',')}}"
  end

  def to_vim_list(array)
    array.map { |value| to_vim_type(value) }.join(',').to_s
  end

  def to_vim_type(value)
    return "''" if value.nil?
    return "'#{value}'" if value.is_a?(String) || value.is_a?(Symbol)

    value
  end
end
