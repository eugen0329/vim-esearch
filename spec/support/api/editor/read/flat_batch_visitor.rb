class API::Editor::Read::FlatBatchVisitor
  attr_reader :reader

  delegate :cached, :cache_exist?, to: :reader

  def initialize(reader)
    @reader = reader
  end

  def accept(object)
    batch = []
    placeholders = []
    visit(object, batch, placeholders)
  end

  private

  def visit(object, batch, placeholders)
    case object
    when Array then visit_array(object, batch, placeholders)
    when Hash then visit_hash(object, batch, placeholders)
    when API::Editor::Serialization::Identifier then visit_identifier(object, batch, placeholders)
    else [object, batch, placeholders]
    end
  end

  def visit_identifier(identifier, batch, placeholders)
    key = [:echo, identifier]
    return [cached(key), batch, placeholders] if cache_exist?(key)

    batch = batch.dup
    batch << identifier
    placeholders << Placeholder(batch.count - 1, identifier)
    [placeholders.last, batch, placeholders]
  end

  def visit_array(array, batch, placeholders)
    batch = batch.dup

    shape = array.map do |value|
      shape, batch, placeholders = visit(value, batch, placeholders)
      shape
    end

    [shape, batch, placeholders]
  end

  def visit_hash(hash, batch, placeholders)
    batch = batch.dup
    placeholders = placeholders.dup

    shape = hash.map do |key, value|
      shape, batch, placeholders = visit(value, batch, placeholders)

      [key, shape]
    end.to_h

    [shape, batch, placeholders]
  end

  def Placeholder(...)
    API::Editor::Read::Batch::Placeholder.new(...)
  end
end
