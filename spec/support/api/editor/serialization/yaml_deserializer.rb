# frozen_string_literal: true

require 'yaml'

class API::Editor::Serialization::YAMLDeserializer
  def deserialize(string)
    return string if toplevel_string?(string)

    parsed = YAML.safe_load(string)

    if parsed.is_a?(String)
      return parsed if parsed.blank?
      return string if string.strip == parsed
    end

    parsed
  end

  # TODO: Consider ro forbid toplevel strings
  def toplevel_string?(string)
    string == '' || string.start_with?(' ')
  end
end
