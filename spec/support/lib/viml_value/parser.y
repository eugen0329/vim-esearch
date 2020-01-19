class VimlValue::Parser
token STRING NUMBER BOOL NULL FUNCREF COLON ','
rule
  toplevel: nothing
  nothing:
end

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

