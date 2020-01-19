class VimlValue::Parser
token STRING NUMERIC BOOLEAN NULL FUNCREF COLON ','
      DICT_RECURSIVE_REF LIST_RECURSIVE_REF
rule
  toplevel: toplevel_value | nothing
  # Consider to disallow toplevel literals
  toplevel_value: value

  value
    : list
    | dict
    | literal

  list
    : '[' values optional_comma ']' { result = @builder.list(val[1]) }
    | '[' ']'                       { result = @builder.list([]) }

  values
    : values ',' value              { result = val[0] << val[2] }
    | value                         { result = [val[0]] }

  dict
    : '{' pairs optional_comma '}'  { result = @builder.dict(val[1]) }
    | '{' '}'                       { result = @builder.dict([]) }

  pairs
    : pairs ',' pair                { result = val[0] << val[2] }
    | pair                          { result = [val[0]] }

  pair: string ':' value            { result = @builder.pair(val[0], val[2]) }

  literal
    : string
    | NUMERIC                       { result = @builder.numeric(val[0]) }
    | BOOLEAN                       { result = @builder.boolean(val[0]) }
    | NULL                          { result = @builder.null(val[0]) }
    | FUNCREF '(' STRING ')'        { result = @builder.funcref(val[2]) }
    | DICT_RECURSIVE_REF            { result = @builder.dict_recursive_ref }
    | LIST_RECURSIVE_REF            { result = @builder.list_recursive_ref }

  string: STRING                    { result = @builder.string(val[0]) }
  optional_comma: ',' | nothing
  nothing:
end

---- header ----

require_relative 'errors'
require_relative 'tree_builder'

---- inner -----

  def initialize(lexer, input)
    @lexer = lexer
    @lexer.scan_setup(input)
    @builder = TreeBuilder.new
    super()
  end

  def parse
    parsed = do_parse
    parsed
  rescue Racc::ParseError => e
    raise VimlValue::ParseError, e.message
  end

  def next_token
    @lexer.next_token
  end
