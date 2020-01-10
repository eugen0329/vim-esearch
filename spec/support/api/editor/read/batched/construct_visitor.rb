class API::Editor::Read::Batched::ConstructVisitor
  attr_reader :reader

  delegate :cached, :cache_exist?, to: :reader

  def initialize(reader)
    @reader = reader
  end

  def accept(object)
    batch = API::Editor::Read::Batched::Batch.new
    visit(object, batch)
  end

  private

  def visit(object, batch)
    case object
    when Array then visit_array(object, batch)
    when Hash then visit_hash(object, batch)
    when API::Editor::Serialization::Identifier then visit_identifier(object, batch)
    else [object, batch]
    end
  end

  def visit_identifier(identifier, batch)
    batch = batch.dup

    placeholder = Placeholder(identifier)
    batch.push(identifier, placeholder)
    [placeholder, batch]
  end

  def visit_array(array, batch)
    batch = batch.dup

    shape = array.map do |value|
      shape, batch = visit(value, batch)
      shape
    end

    [shape, batch]
  end

  def visit_hash(hash, batch)
    batch = batch.dup
    placeholders = placeholders.dup

    shape = hash.map do |key, value|
      shape, batch = visit(value, batch)

      [key, shape]
    end.to_h

    [shape, batch]
  end

  def Placeholder(...)
    API::Editor::Read::Batched::Placeholder.new(...)
  end
end
