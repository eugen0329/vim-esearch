# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Lexer do
  include Helpers::VimlValue::Tokenize
  include Helpers::VimlValue
  ParseError = VimlValue::ParseError

  let(:encoding) { Encoding::ASCII }
  subject(:tokenizing) do
    ->(str) { VimlValue::Lexer.new(str.dup.force_encoding(encoding)).each_token.to_a }
  end

  # NOTE It is crucial for readability to keep indentations for visual
  # comprasion, so
  #   expect(actual).to become(expected).after(method)     }
  #   expect(actual).to fail_with(exception).while(method) }
  # is used instead of
  #   expect(method.call(actual)).to    eq(expected)           }
  #   expect { method.call(actual) }.to raise_error(exception) }
  # Also it's impossible to obtain actual being processed within block, so it
  # allows having better output messages

  context 'NUMERIC' do
    context 'integer' do
      it { expect('1').to   become([[:NUMERIC, val(1, [0, 1])]]).after(tokenizing)    }
      it { expect('0').to   become([[:NUMERIC, val(0, [0, 1])]]).after(tokenizing)    }

      context 'after +|- sign' do
        it { expect('+1').to  become([[:NUMERIC, val(1, [0, 2])]]).after(tokenizing)  }
        it { expect('+0').to  become([[:NUMERIC, val(0, [0, 2])]]).after(tokenizing)  }
        it { expect('-1').to  become([[:NUMERIC, val(-1, [0, 2])]]).after(tokenizing) }
        it { expect('-0').to  become([[:NUMERIC, val(0, [0, 2])]]).after(tokenizing)  }
      end

      context 'leading zeros' do
        it { expect('01').to  become([[:NUMERIC, val(1, [0, 2])]]).after(tokenizing)  }
        it { expect('-01').to become([[:NUMERIC, val(-1, [0, 3])]]).after(tokenizing) }
      end
    end

    context 'float' do
      it { expect('1.0').to become([[:NUMERIC, val(1.0, [0, 3])]]).after(tokenizing) }
      it { expect('1.2').to become([[:NUMERIC, val(1.2, [0, 3])]]).after(tokenizing) }
      it { expect('0.2').to become([[:NUMERIC, val(0.2, [0, 3])]]).after(tokenizing) }
      it { expect('1.').to  fail_with(ParseError).while(tokenizing)                  }
      it { expect('.1').to  fail_with(ParseError).while(tokenizing)                  }

      context 'leading zeros' do
        it { expect('01.0').to  become([[:NUMERIC, val(1.0,  [0, 4])]]).after(tokenizing) }
        it { expect('-01.0').to become([[:NUMERIC, val(-1.0, [0, 5])]]).after(tokenizing) }
      end

      context 'with +|- sign' do
        it { expect('+1.2').to become([[:NUMERIC, val(1.2, [0, 4])]]).after(tokenizing)    }
        it { expect('+1.0').to become([[:NUMERIC, val(1.0, [0, 4])]]).after(tokenizing)    }
        it { expect('+0.2').to become([[:NUMERIC, val(0.2, [0, 4])]]).after(tokenizing)    }

        it { expect('-1.0').to become([[:NUMERIC, val(-1.0, [0, 4])]]).after(tokenizing)   }
        it { expect('-1.2').to become([[:NUMERIC, val(-1.2, [0, 4])]]).after(tokenizing)   }
        it { expect('-0.2').to become([[:NUMERIC, val(-0.2, [0, 4])]]).after(tokenizing)   }
      end

      context 'exponential form' do
        it { expect('1.2e34').to   become([[:NUMERIC, val(1.2e34,  [0, 6])]]).after(tokenizing) }
        it { expect('1.2e034').to  become([[:NUMERIC, val(1.2e34,  [0, 7])]]).after(tokenizing) }
        it { expect('1.2e+34').to  become([[:NUMERIC, val(1.2e34,  [0, 7])]]).after(tokenizing) }
        it { expect('1.2e+034').to become([[:NUMERIC, val(1.2e34,  [0, 8])]]).after(tokenizing) }
        it { expect('1.2e-34').to  become([[:NUMERIC, val(1.2e-34, [0, 7])]]).after(tokenizing) }
        it { expect('1.2e-34').to  become([[:NUMERIC, val(1.2e-34, [0, 7])]]).after(tokenizing) }

        it { expect('1.2E34').to   become([[:NUMERIC, val(1.2e34,  [0, 6])]]).after(tokenizing) }
        it { expect('1.2E034').to  become([[:NUMERIC, val(1.2e34,  [0, 7])]]).after(tokenizing) }
        it { expect('1.2E+34').to  become([[:NUMERIC, val(1.2e34,  [0, 7])]]).after(tokenizing) }
        it { expect('1.2E+034').to become([[:NUMERIC, val(1.2e34,  [0, 8])]]).after(tokenizing) }
        it { expect('1.2E-34').to  become([[:NUMERIC, val(1.2e-34, [0, 7])]]).after(tokenizing) }
        it { expect('1.2E-34').to  become([[:NUMERIC, val(1.2e-34, [0, 7])]]).after(tokenizing) }
      end
    end
  end

  context 'BOOLEAN' do
    it { expect('v:true').to  become([[:BOOLEAN, val(true,  [0, 6])]]).after(tokenizing) }
    it { expect('v:false').to become([[:BOOLEAN, val(false, [0, 7])]]).after(tokenizing).after(tokenizing) }
    it { expect(':true').to   fail_with(ParseError).while(tokenizing) }
    it { expect(':false').to  fail_with(ParseError).while(tokenizing) }
    it { expect('true').to    fail_with(ParseError).while(tokenizing) }
    it { expect('false').to   fail_with(ParseError).while(tokenizing) }
  end

  context 'DICT_RECURSIVE_REF' do
    it { expect(%q|{...}|).to  become([[:DICT_RECURSIVE_REF, val(nil, [0, 5])]]).after(tokenizing) }
    it { expect(%q|{....}|).to fail_with(ParseError).while(tokenizing) }
    it { expect(%q|{..}|).to   fail_with(ParseError).while(tokenizing) }
    it { expect(%q|{.}|).to    fail_with(ParseError).while(tokenizing) }
  end

  context 'LIST_RECURSIVE_REF' do
    it { expect(%q|[...]|).to  become([[:LIST_RECURSIVE_REF, val(nil, [0, 5])]]).after(tokenizing) }
    it { expect(%q|[....]|).to fail_with(ParseError).while(tokenizing) }
    it { expect(%q|[..]|).to   fail_with(ParseError).while(tokenizing) }
    it { expect(%q|[.]|).to    fail_with(ParseError).while(tokenizing) }
  end

  context 'FUNCREF' do
    it do
      expect("function('tr')")
        .to become([[:FUNCREF, val(nil,  [0,  8])],
                    ['(',      val('(',  [8,  9])],
                    [:STRING,  val('tr', [9, 13])],
                    [')',      val(')',  [13, 14])]]).after(tokenizing)
    end
  end

  context 'STRING' do
    it { expect("'1'").to    become([[:STRING, val('1',  [0, 3])]]).after(tokenizing) }
    it { expect('"1"').to    become([[:STRING, val('1',  [0, 3])]]).after(tokenizing) }
    it { expect(%q|"''"|).to become([[:STRING, val("''", [0, 4])]]).after(tokenizing) }
    it { expect(%q|'""'|).to become([[:STRING, val('""', [0, 4])]]).after(tokenizing) }

    context 'UTF-8 encoding' do
      let(:encoding) { Encoding::UTF_8 }

      it { expect("'Σ'").to become([[:STRING, val('Σ', [0, 3])]]).after(tokenizing) }
    end
  end

  context 'SEPARATOR' do
    it { expect(':').to become([[':', val(':', [0, 1])]]).after(tokenizing) }
    it { expect(',').to become([[',', val(',', [0, 1])]]).after(tokenizing) }
    it { expect('{').to become([['{', val('{', [0, 1])]]).after(tokenizing) }
    it { expect('}').to become([['}', val('}', [0, 1])]]).after(tokenizing) }
    it { expect('(').to become([['(', val('(', [0, 1])]]).after(tokenizing) }
    it { expect(')').to become([[')', val(')', [0, 1])]]).after(tokenizing) }
    it { expect('[').to become([['[', val('[', [0, 1])]]).after(tokenizing) }
    it { expect(']').to become([[']', val(']', [0, 1])]]).after(tokenizing) }
  end
end
