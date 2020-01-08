# frozen_string_literal: true

require 'yaml'

class API::ESearch::Editor::Serialization::Deserializer
  def deserialize(string)
    return string if string == ''

    parsed = YAML.safe_load(string)
    return string if parsed.is_a?(String) && string.include?(parsed)

    parsed
  rescue StandardError
    string
  end
end
