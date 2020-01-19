# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Lexer do
  include Helpers::VimlValue::Tokenize

  context 'NUMERIC' do
    context 'integer' do
      it { expect('1').to   be_tokenized_as([[:NUMERIC, val(1, [0, 1])]])    }
      it { expect('0').to   be_tokenized_as([[:NUMERIC, val(0, [0, 1])]])    }

      context 'with +|- sign' do
        it { expect('+1').to  be_tokenized_as([[:NUMERIC, val(1, [0, 2])]])  }
        it { expect('+0').to  be_tokenized_as([[:NUMERIC, val(0, [0, 2])]])  }
        it { expect('-1').to  be_tokenized_as([[:NUMERIC, val(-1, [0, 2])]]) }
        it { expect('-0').to  be_tokenized_as([[:NUMERIC, val(0, [0, 2])]])  }
      end

      context 'leading zeros' do
        it { expect('01').to  be_tokenized_as([[:NUMERIC, val(1, [0, 2])]])  }
        it { expect('-01').to be_tokenized_as([[:NUMERIC, val(-1, [0, 3])]]) }
      end
    end

    context 'float' do
      it { expect('1.0').to be_tokenized_as([[:NUMERIC, val(1.0, [0, 3])]]) }
      it { expect('1.2').to be_tokenized_as([[:NUMERIC, val(1.2, [0, 3])]]) }
      it { expect('0.2').to be_tokenized_as([[:NUMERIC, val(0.2, [0, 3])]]) }
      it { expect('1.').to  raise_on_tokenizing(VimlValue::ParseError)      }
      it { expect('.1').to  raise_on_tokenizing(VimlValue::ParseError)      }

      context 'leading zeros' do
        it { expect('01.0').to  be_tokenized_as([[:NUMERIC, val(1.0,  [0, 4])]]) }
        it { expect('-01.0').to be_tokenized_as([[:NUMERIC, val(-1.0, [0, 5])]]) }
      end

      context 'with +|- sign' do
        it { expect('+1.2').to be_tokenized_as([[:NUMERIC, val(1.2, [0, 4])]])    }
        it { expect('+1.0').to be_tokenized_as([[:NUMERIC, val(1.0, [0, 4])]])    }
        it { expect('+0.2').to be_tokenized_as([[:NUMERIC, val(0.2, [0, 4])]])    }

        it { expect('-1.0').to be_tokenized_as([[:NUMERIC, val(-1.0, [0, 4])]])   }
        it { expect('-1.2').to be_tokenized_as([[:NUMERIC, val(-1.2, [0, 4])]])   }
        it { expect('-0.2').to be_tokenized_as([[:NUMERIC, val(-0.2, [0, 4])]])   }
      end

      context 'exponential form' do
        it { expect('1.2e34').to   be_tokenized_as([[:NUMERIC, val(1.2e34,  [0, 6])]]) }
        it { expect('1.2e034').to  be_tokenized_as([[:NUMERIC, val(1.2e34,  [0, 7])]]) }
        it { expect('1.2e+34').to  be_tokenized_as([[:NUMERIC, val(1.2e34,  [0, 7])]]) }
        it { expect('1.2e+034').to be_tokenized_as([[:NUMERIC, val(1.2e34,  [0, 8])]]) }
        it { expect('1.2e-34').to  be_tokenized_as([[:NUMERIC, val(1.2e-34, [0, 7])]]) }
        it { expect('1.2e-34').to  be_tokenized_as([[:NUMERIC, val(1.2e-34, [0, 7])]]) }

        it { expect('1.2E34').to   be_tokenized_as([[:NUMERIC, val(1.2e34,  [0, 6])]]) }
        it { expect('1.2E034').to  be_tokenized_as([[:NUMERIC, val(1.2e34,  [0, 7])]]) }
        it { expect('1.2E+34').to  be_tokenized_as([[:NUMERIC, val(1.2e34,  [0, 7])]]) }
        it { expect('1.2E+034').to be_tokenized_as([[:NUMERIC, val(1.2e34,  [0, 8])]]) }
        it { expect('1.2E-34').to  be_tokenized_as([[:NUMERIC, val(1.2e-34, [0, 7])]]) }
        it { expect('1.2E-34').to  be_tokenized_as([[:NUMERIC, val(1.2e-34, [0, 7])]]) }
      end
    end
  end

  context 'BOOLEAN' do
    it { expect('v:true').to  be_tokenized_as([[:BOOLEAN, val(true,  [0, 6])]]) }
    it { expect('v:false').to be_tokenized_as([[:BOOLEAN, val(false, [0, 7])]]) }
    it { expect(':true').to   raise_on_tokenizing(VimlValue::ParseError) }
    it { expect(':false').to  raise_on_tokenizing(VimlValue::ParseError) }
    it { expect('true').to    raise_on_tokenizing(VimlValue::ParseError) }
    it { expect('false').to   raise_on_tokenizing(VimlValue::ParseError) }
  end

  context 'DICT_RECURSIVE_REF' do
    it { expect(%q|{...}|).to  be_tokenized_as([[:DICT_RECURSIVE_REF, val(nil, [0, 5])]]) }
    it { expect(%q|{....}|).to raise_on_tokenizing(VimlValue::ParseError) }
    it { expect(%q|{..}|).to   raise_on_tokenizing(VimlValue::ParseError) }
    it { expect(%q|{.}|).to    raise_on_tokenizing(VimlValue::ParseError) }
  end

  context 'LIST_RECURSIVE_REF' do
    it { expect(%q|[...]|).to  be_tokenized_as([[:LIST_RECURSIVE_REF, val(nil, [0, 5])]]) }
    it { expect(%q|[....]|).to raise_on_tokenizing(VimlValue::ParseError) }
    it { expect(%q|[..]|).to   raise_on_tokenizing(VimlValue::ParseError) }
    it { expect(%q|[.]|).to    raise_on_tokenizing(VimlValue::ParseError) }
  end

  context 'FUNCREF' do
    it do
      expect("function('tr')")
        .to be_tokenized_as([[:FUNCREF, val(nil,  [0,  8])],
                             ['(',      val('(',  [8,  9])],
                             [:STRING,  val('tr', [9, 13])],
                             [')',      val(')',  [13, 14])]])
    end
  end

  context 'STRING' do
    it { expect("'1'").to    be_tokenized_as([[:STRING, val('1',  [0, 3])]])  }
    it { expect('"1"').to    be_tokenized_as([[:STRING, val('1',  [0, 3])]])  }
    it { expect(%q|"''"|).to be_tokenized_as([[:STRING, val("''", [0, 4])]]) }
    it { expect(%q|'""'|).to be_tokenized_as([[:STRING, val('""', [0, 4])]]) }
  end

  context 'SEPARATOR' do
    it { expect(':').to be_tokenized_as([[':', val(':', [0, 1])]]) }
    it { expect(',').to be_tokenized_as([[',', val(',', [0, 1])]]) }
    it { expect('{').to be_tokenized_as([['{', val('{', [0, 1])]]) }
    it { expect('}').to be_tokenized_as([['}', val('}', [0, 1])]]) }
    it { expect('(').to be_tokenized_as([['(', val('(', [0, 1])]]) }
    it { expect(')').to be_tokenized_as([[')', val(')', [0, 1])]]) }
    it { expect('[').to be_tokenized_as([['[', val('[', [0, 1])]]) }
    it { expect(']').to be_tokenized_as([[']', val(']', [0, 1])]]) }
  end
end
