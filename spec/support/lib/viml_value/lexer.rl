# frozen_string_literal: true

require_relative 'errors'

module VimlValue
  class Lexer
    %%{
      machine lexer; # % fix syntax highlight
      access self.;
      getkey (data_unpacked[p] || self.class.lexer_ex_eof_ch);

      integer      = '-'?[1-9][0-9]*;
      float        = '-'?('0'|[1-9][0-9]*)'.'[0-9]+;
      double_quote = '"';
      single_quote = "'";
      vtrue        = 'v:true';
      vfalse       = 'v:false';
      vnull        = 'v:null';
      funcref      = 'function';
      # dict_recursive_ref = '{...}';
      # list_recursive_ref = '[...]';

      backslash    = '\\';
      tab          = [\t];
      whitespace   = [ ];
      separator    = [:,{}()\[\]];

      export eof_ch = 0;
      any_ch        = any - eof_ch;

      main := |*
        (whitespace | tab)*;
        integer            => { emit(:NUMBER, data[ts...te].to_i)    };
        float              => { emit(:NUMBER, data[ts...te].to_f)    };
        single_quote       => { start_str!; fcall single_quoted_str; };
        double_quote       => { start_str!; fcall double_quoted_str; };
        vtrue              => { emit(:BOOL,  true)                   };
        vfalse             => { emit(:BOOL, false)                   };
        vnull              => { emit(:NULL,  nil)                    };
        funcref            => { emit(:FUNCREF, nil)                  };
        # dict_recursive_ref => { emit(:DICT_RECURSIVE_REF, nil)       };
        # list_recursive_ref => { emit(:LIST_RECURSIVE_REF, nil)       };
        separator          => { emit(data[ts], data[ts])             };
        eof_ch             => { fbreak;                              };
        any_ch             => { raise ParseError, "Unexpected char"; };
      *|;

      single_quoted_str := |*
        single_quote    => { end_and_emit_str!; fret;           };
        single_quote{2} => { str_append! single_quote;          };
        any_ch          => { str_append! data[ts...te]          };
        eof_ch          => { raise ParseError, "Unexpected end" };
      *|;

      double_quoted_str := |*
        double_quote           => { end_and_emit_str!; fret;           };
        backslash single_quote => { str_append! single_quote;          };
        backslash double_quote => { str_append! double_quote;          };
        backslash{2}           => { str_append! backslash;             };
        any_ch                 => { str_append! data[ts...te]          };
        eof_ch                 => { raise ParseError, "Unexpected end" };
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

    TokenData = Struct.new(:val)

    def emit(type, val)
      @block.call([type, TokenData.new(val)])
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
