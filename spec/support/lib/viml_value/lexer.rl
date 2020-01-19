# frozen_string_literal: true

module VimlValue
  class Lexer
    %%{
      machine lexer; # % fix syntax highlight
      access self.;
      getkey (data_unpacked[p] || self.class.lexer_ex_eof_ch);

      ### Vim types (from :h type())
      # Number:     0 (|v:t_number|)
      # String:     1 (|v:t_string|)
      # Funcref:    2 (|v:t_func|)
      # List:       3 (|v:t_list|)
      # Dictionary: 4 (|v:t_dict|)
      # Float:      5 (|v:t_float|)
      # Boolean:    6 (|v:true| and |v:false|)
      # Null:       7 (|v:null|)

      number       = [+\-]?[0-9]+;
      float        = [+\-]?[0-9]+'.'[0-9]+([Ee][+\-]?[0-9]+)?;
      double_quote = '"';
      single_quote = "'";
      vtrue        = 'v:true';
      vfalse       = 'v:false';
      vnull        = 'v:null';
      funcref      = 'function';
      dict_recursive_ref = '{...}';
      list_recursive_ref = '[...]';

      backslash    = '\\';
      tab          = [\t];
      whitespace   = [ ];
      separator    = [:,{}()\[\]];

      export eof_ch = 0;
      any_ch        = any - eof_ch;

      main := |*
        (whitespace | tab)*;
        number             => { emit(:NUMERIC, token.to_i)           };
        float              => { emit(:NUMERIC, token.to_f)           };
        single_quote       => { start_str!; fcall single_quoted_str; };
        double_quote       => { start_str!; fcall double_quoted_str; };
        vtrue              => { emit(:BOOLEAN, true)                 };
        vfalse             => { emit(:BOOLEAN, false)                };
        vnull              => { emit(:NULL,  nil)                    };
        funcref            => { emit(:FUNCREF, nil)                  };
        dict_recursive_ref => { emit(:DICT_RECURSIVE_REF, nil)       };
        list_recursive_ref => { emit(:LIST_RECURSIVE_REF, nil)       };
        separator          => { emit(data[ts], data[ts])             };
        eof_ch             => { fbreak;                              };
        any_ch             => { failure "Unexpected char"            };
      *|;

      single_quoted_str := |*
        single_quote    => { end_and_emit_str!; fret;           };
        single_quote{2} => { str_append! single_quote;          };
        any_ch          => { str_append! token                  };
        eof_ch          => { failure "Unexpected end of string" };
      *|;

      double_quoted_str := |*
        double_quote           => { end_and_emit_str!; fret;           };
        backslash single_quote => { str_append! single_quote;          };
        backslash double_quote => { str_append! double_quote;          };
        backslash{2}           => { str_append! backslash;             };
        any_ch                 => { str_append! token                  };
        eof_ch                 => { failure "Unexpected end of string" };
      *|;

    }%%
    # % fix syntax highlight

    %% write exports;
    %% write data;
    # Setup ragel methods. Ugly, but at least less dependent on ragel internal
    # naming like with assigning all the values manually
    private_methods.select { |m| m.to_s =~ /\A_lexer.*[^=]\z/ }
      .each { |m| define_method(m) { self.class.send(m) } }

    def each(&block)
      return enum_for(:each) if block.nil?

      @block = block

      p = @p
      %% write exec noend;
      # %
      @p = p # preserve data pointer just in case
    ensure
      @block = nil
    end

    def next_token
      @iterator.next
    rescue StopIteration
      nil
    end

    # input
    attr_reader :data, :data_unpacked
    # for ragel
    attr_accessor :ts, :te, :stack, :top, :cs, :act, :p

    def scan_setup(input)
      @data = input
      @data_unpacked = input.unpack("C*")
      @iterator = each

      # for ragel
      @ts, @te     = nil,  nil            # start, end position
      @stack, @top = [], 0                # for fcall and fret
      @cs          = %%{ write start; }%% # current state
      @act         = 0                    # most recent successful pattern match
      @p = 0                              # data pointer
    end

    private

    def token
      data[ts...te]
    end

    def failure(message, value = nil)
      message = [message, value].join(': ')
      message = [message, 'at', p].join(' ')
      raise ParseError, message
    end

    TokenData = Struct.new(:val, :start, :end)

    def emit(type, val)
      @block.call([type, TokenData.new(val, ts, te)])
    end

    def single_quote
      "'"
    end

    def double_quote
      '"'
    end

    def backslash
      '\\'
    end

    def start_str!
      @str_buffer = String.new
    end

    def str_append!(tail)
      @str_buffer << tail
    end

    def end_and_emit_str!
      emit(:STRING, @str_buffer);
      @str_buffer = nil
    end
  end
end
