# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/cache'

class Editor::Read::Eager < Editor::Read::Base
  def echo(serializable_argument)
    cache.fetch(serializable_argument) do
      VimlValue.load(evaluate(VimlValue.dump([serializable_argument])))[0]
    end
  end
end
