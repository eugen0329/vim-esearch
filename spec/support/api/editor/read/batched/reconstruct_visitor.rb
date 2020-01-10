class API::Editor::Read::Batched::ReconstructVisitor
  attr_reader :reader

  delegate :cache, :cached, :cache_exist?, to: :reader

  def initialize(reader)
    @reader = reader
  end

  def accept(shape, evaluated_batch)
    visit(shape, evaluated_batch)
  end

  private

  def visit(shape, evaluated_batch)
    case shape
    when Array then visit_array(shape, evaluated_batch)
    when Hash then visit_hash(shape, evaluated_batch)
    when API::Editor::Read::Batched::Placeholder then visit_placeholder(shape, evaluated_batch)
    else shape
    end
  end

  def visit_placeholder(placeholder, evaluated_batch)
    placeholder.value
    # evaluated_batch[]
  end

  def visit_hash(shape, evaluated_batch)
    val = shape.map { |key, value| [key, visit(value, evaluated_batch)] }.to_h
  end

  def visit_array(shape, evaluated_batch)
    shape.map { |value| visit(value, evaluated_batch) }
  end
end
