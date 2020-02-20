# frozen_string_literal: true

class VimlValue::TreeBuilder
  def numeric(tstring)
    node(:numeric, [token_value(tstring)])
  end

  def boolean(tstring)
    node(:boolean, [token_value(tstring)])
  end

  def none
    node(:none)
  end

  def null(tnull)
    node(:null, [token_value(tnull)])
  end

  def funcref(tstring, *curried_args)
    node(:funcref, [tstring, *curried_args])
  end

  def string(tstring)
    node(:string, [token_value(tstring)])
  end

  def dict(pairs)
    node(:dict, pairs)
  end

  def list(values)
    node(:list, values)
  end

  def pair(key, token_value)
    node(:pair, [key, token_value])
  end

  def dict_recursive_ref
    node(:dict_recursive_ref)
  end

  def list_recursive_ref
    node(:list_recursive_ref)
  end

  private

  def token_value(token)
    token.value
  end

  def node(type, children = [])
    VimlValue::AST::Node.new(type, children.freeze)
  end
end
