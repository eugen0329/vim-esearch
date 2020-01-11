# frozen_string_literal: true

require 'yaml'

class API::Editor::Serialization::YAMLDeserializer
  def deserialize(string)
    return string if string == '' || string.start_with?(' ')

    parsed = YAML.safe_load(string)

    if parsed.is_a?(String)
      return parsed if parsed.blank?
      return string if string.strip == parsed
    end

    parsed
  rescue StandardError
    string
  end
end
