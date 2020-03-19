# frozen_string_literal: true

module Helpers::Modifiable::Write
  def write_with_confirmation
    editor.send_keys_separately ':write', :enter, 'y'
  end
end
