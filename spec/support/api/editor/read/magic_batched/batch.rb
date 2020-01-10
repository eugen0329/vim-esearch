class API::Editor::Read::MagicBatched::Batch
  attr_reader :blank_containers, :loaded_containers

  def initialize(eager_method)
    @eager_method = eager_method
    @blank_containers  = []
    @loaded_containers = []
  end

  def eager!
    @eager_method.call
  end

  def push(container)
    blank_containers << container
    self
  end

  def clear
    blank_containers.clear
    loaded_containers.clear
    self
  end

  def lookup!(identity_map)
    retrieved, @blank_containers = blank_containers.partition do |container|
      next false unless identity_map.exist?(container.__argument__)
      container.__value__ = identity_map.fetch(container.__argument__)
      true
    end
    loaded_containers.concat(retrieved)

    self
  end

  def evaluate!(&evaluator)
    return self unless blank_containers.present?

    values = blank_containers
      .map(&:__argument__)
      .yield_self(&evaluator)
    blank_containers
      .zip(values)
      .each { |container, value| container.__value__ = value }
    loaded_containers.concat(blank_containers)
    blank_containers.clear

    self
  end

  def write(identity_map)
    loaded_containers.each do |container|
      next if identity_map.exist?(container.__argument__)

      identity_map.write(container.__argument__, container.__value__)
    end
  end
end
