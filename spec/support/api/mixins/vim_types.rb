# frozen_string_literal: true

module API::Mixins::VimTypes
  def to_vim_dict(hash)
    pairs = hash.map do |key, value|
      value = to_vim_type(value)
      "'#{key}': #{value}"
    end
    "{#{pairs.join(',')}}"
  end

  def to_vim_type(value)
    "'#{value}'" unless value.is_a? Numeric
    value
  end
end
