# frozen_string_literal: true

class VimlValue::Visitors::ToVim7 < VimlValue::Visitors::ToVim
  def visit_nil(_object)
    "''"
  end
end
