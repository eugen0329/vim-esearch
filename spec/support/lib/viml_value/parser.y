class VimlValue::Parser
token STRING NUMERIC BOOLEAN NONE NULL FUNCREF
      DICT_RECURSIVE_REF LIST_RECURSIVE_REF
rule
  toplevel:
    : list
    | dict
    | literal                           { raise_unless_toplevel_literals_allowed }
    | nothing

  value
    : list
    | dict
    | literal

  list
    : '[' values optional_comma ']'     { result = @builder.list(val[1]) }
    | '[' ']'                           { result = @builder.list([]) }

  values
    : values ',' value                  { result = val[0] << val[2] }
    | value                             { result = [val[0]] }

  dict
    : '{' pairs optional_comma '}'      { result = @builder.dict(val[1]) }
    | '{' '}'                           { result = @builder.dict([]) }

  pairs
    : pairs ',' pair                    { result = val[0] << val[2] }
    | pair                              { result = [val[0]] }

  pair: string ':' value                { result = @builder.pair(val[0], val[2]) }

  literal
    : string
    | funcref
    | NUMERIC                           { result = @builder.numeric(val[0]) }
    | BOOLEAN                           { result = @builder.boolean(val[0]) }
    | NULL                              { result = @builder.null(val[0]) }
    | NONE                              { result = @builder.none }
    | DICT_RECURSIVE_REF                { result = @builder.dict_recursive_ref }
    | LIST_RECURSIVE_REF                { result = @builder.list_recursive_ref }

    funcref
    : FUNCREF '(' string ')'            { result = @builder.funcref(val[2]) }
    | FUNCREF '(' string ',' values ')' { result = @builder.funcref(val[2], *val[4]) }

  string: STRING                        { result = @builder.string(val[0]) }

  optional_comma: ',' | nothing
  nothing:
end

---- inner -----

  def initialize(lexer, allow_toplevel_literals: false)
    @lexer = lexer
    @builder = VimlValue::TreeBuilder.new
    @allow_toplevel_literals = allow_toplevel_literals
    super()
  end

  def parse
    @lexer.reset!
    do_parse
  end

  private

  def next_token
    @lexer.next_token
  end

  def on_error(token_id, value, value_stack)
    if token_to_str(token_id) == '$end'
      raise ParseError, "#{context}Unexpected end of tokens stream"
    else
      location = [value.start, value.end].join(':')
      raise ParseError,  "#{context}Unexpected token #{token_to_str(token_id)} at location #{location}"
    end
  end

  def raise_unless_toplevel_literals_allowed
    return if @allow_toplevel_literals
    raise ParseError, "#{context}Toplevel lietrals aren't allowed due to parsing ambiguity"
  end

  def context
    "While parsing: #{@lexer.data}\n"
  end
