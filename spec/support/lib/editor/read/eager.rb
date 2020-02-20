# frozen_string_literal: true

require 'active_support/cache'

class Editor::Read::Eager < Editor::Read::Base
  def echo(serializable_argument)
    cache.fetch(serializable_argument) do
      # NOTE: execution is wrapped in [] to prevent ambiguity in VimlValue#load
      VimlValue.load(evaluate(VimlValue.dump([serializable_argument])))[0]
    end
  end
end
