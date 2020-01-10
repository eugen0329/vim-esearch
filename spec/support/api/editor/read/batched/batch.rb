class API::Editor::Read::Batched::Batch < Hash
  include TaggedLogging

  def push(identifier, placeholder)
    self.[]=(identifier, placeholder)
    self
  end

  def identifiers
    keys
  end

  def placeholders
    values
  end

  def lookup!(identity_map)
    # log_debug do
    #   # require 'pry'; binding.pry if identity_map.present?
    #   "cached: #{identity_map.read_multi(*identifiers).transform_keys(&:to_s)}"
    # end

    each do |id, placeholder|
      placeholder.value = identity_map.fetch(id) if identity_map.exist?(id)
    end

    self
  end

  def evaluate!(&evaluator)
    lost_identifiers, lost_placeholders = self
      .select { |id, placeholder| placeholder.empty? }
      .to_a
      .transpose

    values = evaluator.call(lost_identifiers)
    # todo
    return self if values.is_a? String

    values.zip(lost_placeholders).each { |value, placeholder| placeholder.value = value  }
    # require 'pry'; binding.pry if placeholders.any?(&:empty?)
    self
  end

  def write(identity_map)
    each do |identifier, placeholder|
      next if identity_map.exist?(identifier)
      identity_map.write(identifier, placeholder.value)
    end
  end
end

