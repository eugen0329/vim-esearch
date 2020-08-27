# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Lexer do
  include Helpers::VimlValue
  ParseError ||= VimlValue::ParseError

  let(:encoding) { Encoding::ASCII }

  describe '#next_token' do
    subject(:tokens_enum) do
      lambda do |str|
        lexer = VimlValue::Lexer.new(str.dup.force_encoding(encoding))
        Enumerator
          .new { |y| loop { y.yield(lexer.next_token) } }
          .take_while(&:present?)
      end
    end

    def be_tokenized_as(expected)
      Helpers::VimlValue::BeTokenizedAs.new(expected, &tokens_enum)
    end

    def fail_tokenizing_with(expected)
      Helpers::VimlValue::FailTokenizingWith.new(expected, &tokens_enum)
    end

    context 'NUMERIC' do
      context 'integer' do
        it { expect('1').to   be_tokenized_as([tok(:NUMERIC, 1, 0..1)]) }
        it { expect('0').to   be_tokenized_as([tok(:NUMERIC, 0, 0..1)]) }

        context 'after +|- sign' do
          it { expect('+1').to be_tokenized_as([tok(:NUMERIC, 1,  0..2)]) }
          it { expect('+0').to be_tokenized_as([tok(:NUMERIC, 0,  0..2)]) }
          it { expect('-1').to be_tokenized_as([tok(:NUMERIC, -1, 0..2)]) }
          it { expect('-0').to be_tokenized_as([tok(:NUMERIC, 0,  0..2)]) }
        end

        context 'leading zeros' do
          it { expect('01').to  be_tokenized_as([tok(:NUMERIC, 1,  0..2)]) }
          it { expect('-01').to be_tokenized_as([tok(:NUMERIC, -1, 0..3)]) }
        end
      end

      context 'float' do
        it { expect('1.0').to be_tokenized_as([tok(:NUMERIC, 1.0, 0..3)]) }
        it { expect('1.2').to be_tokenized_as([tok(:NUMERIC, 1.2, 0..3)]) }
        it { expect('0.2').to be_tokenized_as([tok(:NUMERIC, 0.2, 0..3)]) }
        it { expect('1.').to  fail_tokenizing_with(ParseError)            }
        it { expect('.1').to  fail_tokenizing_with(ParseError)            }

        context 'leading zeros' do
          it { expect('01.0').to  be_tokenized_as([tok(:NUMERIC, 1.0,  0..4)]) }
          it { expect('-01.0').to be_tokenized_as([tok(:NUMERIC, -1.0, 0..5)]) }
        end

        context 'with +|- sign' do
          it { expect('+1.2').to be_tokenized_as([tok(:NUMERIC, 1.2, 0..4)])  }
          it { expect('+1.0').to be_tokenized_as([tok(:NUMERIC, 1.0, 0..4)])  }
          it { expect('+0.2').to be_tokenized_as([tok(:NUMERIC, 0.2, 0..4)])  }

          it { expect('-1.0').to be_tokenized_as([tok(:NUMERIC, -1.0, 0..4)]) }
          it { expect('-1.2').to be_tokenized_as([tok(:NUMERIC, -1.2, 0..4)]) }
          it { expect('-0.2').to be_tokenized_as([tok(:NUMERIC, -0.2, 0..4)]) }
        end

        context 'exponential form' do
          it { expect('1.2e34').to   be_tokenized_as([tok(:NUMERIC, 1.2e34,  0..6)]) }
          it { expect('1.2e034').to  be_tokenized_as([tok(:NUMERIC, 1.2e34,  0..7)]) }
          it { expect('1.2e+34').to  be_tokenized_as([tok(:NUMERIC, 1.2e34,  0..7)]) }
          it { expect('1.2e+034').to be_tokenized_as([tok(:NUMERIC, 1.2e34,  0..8)]) }
          it { expect('1.2e-34').to  be_tokenized_as([tok(:NUMERIC, 1.2e-34, 0..7)]) }
          it { expect('1.2e-34').to  be_tokenized_as([tok(:NUMERIC, 1.2e-34, 0..7)]) }

          it { expect('1.2E34').to   be_tokenized_as([tok(:NUMERIC, 1.2e34,  0..6)]) }
          it { expect('1.2E034').to  be_tokenized_as([tok(:NUMERIC, 1.2e34,  0..7)]) }
          it { expect('1.2E+34').to  be_tokenized_as([tok(:NUMERIC, 1.2e34,  0..7)]) }
          it { expect('1.2E+034').to be_tokenized_as([tok(:NUMERIC, 1.2e34,  0..8)]) }
          it { expect('1.2E-34').to  be_tokenized_as([tok(:NUMERIC, 1.2e-34, 0..7)]) }
          it { expect('1.2E-34').to  be_tokenized_as([tok(:NUMERIC, 1.2e-34, 0..7)]) }
        end
      end
    end

    context 'BOOLEAN' do
      it { expect('v:true').to  be_tokenized_as([tok(:BOOLEAN, true,  0..6)]) }
      it { expect('v:false').to be_tokenized_as([tok(:BOOLEAN, false, 0..7)]) }
      it { expect('g:true').to  fail_tokenizing_with(ParseError) }
      it { expect('g:false').to fail_tokenizing_with(ParseError) }
      it { expect(':true').to   fail_tokenizing_with(ParseError) }
      it { expect(':false').to  fail_tokenizing_with(ParseError) }
      it { expect('true').to    fail_tokenizing_with(ParseError) }
      it { expect('false').to   fail_tokenizing_with(ParseError) }
    end

    context 'NULL' do
      it { expect('v:null').to  be_tokenized_as([tok(:NULL, nil, 0..6)]) }
      it { expect('g:null').to  fail_tokenizing_with(ParseError) }
      it { expect(':null').to   fail_tokenizing_with(ParseError) }
      it { expect('null').to    fail_tokenizing_with(ParseError) }
    end

    context 'NONE' do
      it { expect('v:none').to  be_tokenized_as([tok(:NONE, nil, 0..6)]) }
      it { expect('None').to    be_tokenized_as([tok(:NONE, nil, 0..4)]) }
      it { expect('g:none').to  fail_tokenizing_with(ParseError) }
      it { expect(':none').to   fail_tokenizing_with(ParseError) }
      it { expect('none').to    fail_tokenizing_with(ParseError) }
    end

    context 'DICT_RECURSIVE_REF' do
      it { expect(%q|{...}|).to  be_tokenized_as([tok(:DICT_RECURSIVE_REF, nil, 0..5)]) }
      it { expect(%q|{....}|).to fail_tokenizing_with(ParseError) }
      it { expect(%q|{..}|).to   fail_tokenizing_with(ParseError) }
      it { expect(%q|{.}|).to    fail_tokenizing_with(ParseError) }
    end

    context 'LIST_RECURSIVE_REF' do
      it { expect(%q|[...]|).to  be_tokenized_as([tok(:LIST_RECURSIVE_REF, nil, 0..5)]) }
      it { expect(%q|[....]|).to fail_tokenizing_with(ParseError) }
      it { expect(%q|[..]|).to   fail_tokenizing_with(ParseError) }
      it { expect(%q|[.]|).to    fail_tokenizing_with(ParseError) }
    end

    context 'FUNCREF' do
      it do
        expect("function('tr')")
          .to be_tokenized_as([tok(:FUNCREF, nil, 0..8),
                               tok('(',      '(',  8..9),
                               tok(:STRING,  'tr', 9..13),
                               tok(')',      ')',  13..14),])
      end
    end

    context 'STRING' do
      it { expect("'1'").to    be_tokenized_as([tok(:STRING, '1',  0..3)]) }
      it { expect('"2"').to    be_tokenized_as([tok(:STRING, '2',  0..3)]) }
      it { expect(%q|"''"|).to be_tokenized_as([tok(:STRING, "''", 0..4)]) }
      it { expect(%q|'""'|).to be_tokenized_as([tok(:STRING, '""', 0..4)]) }

      context 'UTF-8 encoding' do
        let(:encoding) { Encoding::UTF_8 }

        it { expect("'Σ'").to be_tokenized_as([tok(:STRING, 'Σ', 0..3)]) }
      end
    end

    context 'SEPARATOR' do
      it { expect(':').to be_tokenized_as([tok(':', ':', 0..1)]) }
      it { expect(',').to be_tokenized_as([tok(',', ',', 0..1)]) }
      it { expect('{').to be_tokenized_as([tok('{', '{', 0..1)]) }
      it { expect('}').to be_tokenized_as([tok('}', '}', 0..1)]) }
      it { expect('(').to be_tokenized_as([tok('(', '(', 0..1)]) }
      it { expect(')').to be_tokenized_as([tok(')', ')', 0..1)]) }
      it { expect('[').to be_tokenized_as([tok('[', '[', 0..1)]) }
      it { expect(']').to be_tokenized_as([tok(']', ']', 0..1)]) }
    end
  end

  describe '#each_token' do
    let(:lexer) { VimlValue::Lexer.new('[]') }
    let(:tokens) { [tok('[', '[', 0..1), tok(']', ']', 1..2)] }
    subject { lexer.each_token }

    it { is_expected.to be_a(Enumerator) }

    context 'sequential call' do
      it { expect(lexer.each_token.to_a).to eq(lexer.each_token.to_a) }

      it do
        2.times do
          expect { |yield_probe| lexer.each_token(&yield_probe) }
            .to yield_successive_args(*tokens)
        end
      end
    end

    context 'rewinding' do
      it { expect(subject.to_a).to        eq(tokens)              }
      it { expect(subject.rewind.to_a).to eq(subject.rewind.to_a) }

      context 'standard enums behavior correspondence' do
        it 'rewinds enumerator on call(&block)' do
          expect { lexer.each_token {} }
            .not_to change { lexer.next_token }
            .from(tokens.first)
        end

        it 'rewinds enumerator on call.to_a' do
          expect { subject.to_a }
            .not_to change { lexer.next_token }
            .from(tokens.first)
        end
      end
    end

    context 'peeking' do
      it { expect(subject.peek).to eq(tokens.first) }
      it { expect(subject.peek).to eq(subject.peek) }
    end
  end

  describe '#reset!' do
    let(:lexer) { VimlValue::Lexer.new('[]') }

    it do
      expect { lexer.reset! }
        .not_to change { lexer.next_token }
        .from(tok('[', '[', 0..1))
    end
  end
end
