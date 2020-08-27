# frozen_string_literal: true

require 'active_support/cache'

class Editor::Read::Batched < Editor::Read::Base
  attr_reader :batch

  def initialize(vim_client_getter, cache_enabled)
    super(vim_client_getter, cache_enabled)
    @batch = Batch.new(method(:eager!))
  end

  def echo(serializable_argument)
    container = Container.new(serializable_argument, batch)
    batch.push(container)
    container
  end

  def evaluated?(container)
    !container.__value__.equal?(Editor::Read::Batched::Container::UNDEFINED)
  end

  def invalidate_cache!
    eager!
    super
  end

  private

  def reset!
    batch.clear
    super
  end

  def eager!
    return false if batch.blank?

    batch
      .lookup!(cache)
      .evaluate! { |viml_values| VimlValue.load(evaluate(VimlValue.dump(viml_values))) }
      .write(cache)
      .clear

    true
  end
end
