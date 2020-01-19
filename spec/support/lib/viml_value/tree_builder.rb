# frozen_string_literal: true

class VimlValue::TreeBuilder
  def numeric(tstring)
    node(:numeric, [val(tstring)])
  end

  def boolean(tstring)
    node(:boolean, [val(tstring)])
  end

  def null(tstring)
    node(:null, [val(tstring)])
  end

  def funcref(tname)
    node(:funcref, [val(tname)])
  end

  def string(tstring)
    node(:string, [val(tstring)])
  end

  def dict(pairs)
    node(:dict, pairs)
  end

  def list(values)
    node(:list, values)
  end

  def pair(key, value)
    node(:string, [key, value])
  end

  def dict_recursive_ref
    node(:dict_recursive_ref)
  end

  def list_recursive_ref
    node(:list_recursive_ref)
  end

  private

  def val(token)
    token.val
  end

  def node(type, children = [])
    VimlValue::AST::Node.new(type, children.freeze)
  end
end
