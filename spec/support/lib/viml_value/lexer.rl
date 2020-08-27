# frozen_string_literal: true

# Big thanks to ruby_parser, graphql-ruby and oga maintainers (who also use
# ragel) for inspiring some implementations ideas and for saving hours (and even
# more) of ragel lexer integration
module VimlValue
  class Lexer
    %%{
      machine lexer; # % fix syntax highlight
      access self.;
      getkey (data_unpacked[p] || self.class.lexer_ex_eof_ch);

      ### Vim types (from :help type())
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
      vnone        = 'v:none' | 'None';
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
        number             => { emit(:NUMERIC, token.to_i)                 };
        float              => { emit(:NUMERIC, token.to_f)                 };
        single_quote       => { start_str!; fcall single_quoted_str;       };
        double_quote       => { start_str!; fcall double_quoted_str;       };
        vtrue              => { emit(:BOOLEAN, true)                       };
        vfalse             => { emit(:BOOLEAN, false)                      };
        vnone              => { emit(:NONE, nil)                           };
        vnull              => { emit(:NULL,  nil)                          };
        funcref            => { emit(:FUNCREF, nil)                        };
        dict_recursive_ref => { emit(:DICT_RECURSIVE_REF, nil)             };
        list_recursive_ref => { emit(:LIST_RECURSIVE_REF, nil)             };
        separator          => { emit(data[ts], data[ts])                   };
        eof_ch             => { fbreak;                                    };
        any_ch             => { failure "Unexpected char #{token.inspect}" };
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


    attr_reader :data, :data_unpacked
    attr_accessor :ts, :te, :stack, :top, :cs, :act, :p # ragel internals

    def initialize(input)
      @data = input
      @data_unpacked =
        if input.encoding == Encoding::UTF_8
          input.unpack("U*")
        else
          input.unpack("C*")
        end
      reset!
    end

    def each_token(&block)
      return @each_token if block.nil?

      @yielder = Enumerator::Yielder.new(&block)
      reset_ragel!

      p = @p
      %% write exec noend;
      # %
      @p = p # preserve data pointer just in case
    ensure
      reset!
    end

    def next_token
      @each_token.next
    rescue StopIteration
      nil
    end

    def reset!
      @each_token = enum_for(:each_token)
      @yielder = nil
    end

    private

    def reset_ragel!
      @ts, @te     = nil,  nil            # start, end position
      @stack, @top = [], 0                # for fcall and fret
      @cs          = %%{ write start; }%% # current state
      @act         = 0                    # most recent successful pattern match
      @p = 0                              # data pointer
    end

    def token
      data[ts...te]
    end

    def failure(message)
      raise ParseError, "#{message} at #{p}. In: #{data.inspect}"
    end

    TokenData = Struct.new(:value, :start, :end) do
      def inspect
        map(&:inspect).join(':')
      end
    end

    def emit(type, val, tstart = ts, tend = te)
      @yielder.yield([type, TokenData.new(val, tstart, tend)])
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
      @str_tstart = ts
    end

    def str_append!(tail)
      @str_buffer << tail
    end

    def end_and_emit_str!
      emit(:STRING, @str_buffer, @str_tstart, te)
      @str_tstart = nil
      @str_buffer = nil
    end
  end
end
