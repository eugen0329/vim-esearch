# frozen_string_literal: true

require_relative 'errors'

module VimlValue
  class Lexer
    %%{
      machine lexer; # %
      access self.;
      getkey (data_unpacked[p] || self.class.lexer_ex_eof_ch);

      integer      = '-'?[1-9][0-9]*;
      float        = '-'?[1-9][0-9]*'.'[0-9]+;
      tab          = [\t];
      whitespace   = [ ];
      separator    = [{}\[\]():,];

      export eof_ch = 0;
      any_ch        = any - eof_ch;

      main := |*
        (whitespace | tab)*;
        integer            => { emit(:NUMBER, data[ts...te].to_i)    };
        float              => { emit(:NUMBER, data[ts...te].to_f)    };
        separator          => { emit(data[ts], data[ts])             };
        eof_ch             => { fbreak;                              };
        any_ch             => { raise ParseError, "Unexpected char"; };
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
  end
end

