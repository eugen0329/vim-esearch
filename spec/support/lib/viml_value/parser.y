class VimlValue::Parser
token STRING NUMBER BOOL NULL FUNCREF COLON ','
rule
  toplevel: toplevel_value | nothing
  # Consider to disallow toplevel literals
  toplevel_value: value

  value
    : list
    | dict
    | literal

  list
    : '[' values ']'     { result = @builder.list(val[1]) }
    | '[' ']'            { result = @builder.list([]) }

  values
    : values ',' value   { result = val[0] << val[2] }
    | value              { result = [val[0]] }

  dict
    : '{' pairs '}'      { result = @builder.dict(val[1]) }
    | '{' '}'            { result = @builder.dict([]) }

  pairs
    : pairs ',' pair     { result = val[0] << val[2] }
    | pair               { result = [val[0]] }

  pair: string ':' value { result = @builder.pair(val[0], val[2]) }

  literal
    : string
    | NUMBER                 { result = @builder.number(val[0]) }
    | BOOL                   { result = @builder.bool(val[0]) }
    | NULL                   { result = @builder.null(val[0]) }
    | FUNCREF '(' STRING ')' { result = @builder.funcref(val[2]) }

  string : STRING            { result = @builder.string(val[0]) }
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
