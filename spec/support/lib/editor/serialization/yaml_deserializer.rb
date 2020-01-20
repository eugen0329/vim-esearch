# frozen_string_literal: true

require 'yaml'

# class Editor::Serialization::YAMLDeserializer
#   class ToplevelUnquotedStrError < RuntimeError; end

#   def deserialize(string, allow_toplevel_unquoted_strings = false)
#     if toplevel_unquoted_string?(string)
#       unless allow_toplevel_unquoted_strings
#         raise ToplevelUnquotedStrError,
#           "Is not allowed for deserialization: #{string.inspect}"
#       end
#       return string
#     end

#     parsed = VimlValue.load(string)

#     if parsed.is_a?(String)
#       return parsed if parsed.blank?
#       return string if string.strip == parsed
#     end

#     parsed
#   end

#   # TODO: Consider ro forbid toplevel strings
#   def toplevel_unquoted_string?(string)
#     string == '' || string.start_with?(' ') || string !~ /\A['"1-9{\[]/
#   end
# end
