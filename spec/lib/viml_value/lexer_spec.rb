# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Lexer do
  include Helpers::VimlValue
  ParseError = VimlValue::ParseError

  # NOTE It is crucial for readability to keep indentations for visual
  # comprasion, so
  #   expect(actual).to become(expected).after(method)     }
  #   expect(actual).to fail_with(exception).while(method) }
  # is used instead of
  #   expect(method.call(actual)).to    eq(expected)           }
  #   expect { method.call(actual) }.to raise_error(exception) }
  # Also it's impossible to obtain actual being processed within block, so it
  # allows having better output messages

  let(:encoding) { Encoding::ASCII }

  describe '#next_token' do
    subject(:tokenizing) do
      lambda do |str|
        lexer = VimlValue::Lexer.new(str.dup.force_encoding(encoding))
        Enumerator
          .new { |y| loop { y.yield(lexer.next_token) } }
          .take_while(&:present?)
      end
    end

    context 'NUMERIC' do
      context 'integer' do
        it { expect('1').to   become([tok(:NUMERIC, 1, 0..1)]).after(tokenizing)    }
        it { expect('0').to   become([tok(:NUMERIC, 0, 0..1)]).after(tokenizing)    }

        context 'after +|- sign' do
          it { expect('+1').to become([tok(:NUMERIC, 1,  0..2)]).after(tokenizing) }
          it { expect('+0').to become([tok(:NUMERIC, 0,  0..2)]).after(tokenizing) }
          it { expect('-1').to become([tok(:NUMERIC, -1, 0..2)]).after(tokenizing) }
          it { expect('-0').to become([tok(:NUMERIC, 0,  0..2)]).after(tokenizing) }
        end

        context 'leading zeros' do
          it { expect('01').to  become([tok(:NUMERIC, 1,  0..2)]).after(tokenizing) }
          it { expect('-01').to become([tok(:NUMERIC, -1, 0..3)]).after(tokenizing) }
        end
      end

      context 'float' do
        it { expect('1.0').to become([tok(:NUMERIC, 1.0, 0..3)]).after(tokenizing) }
        it { expect('1.2').to become([tok(:NUMERIC, 1.2, 0..3)]).after(tokenizing) }
        it { expect('0.2').to become([tok(:NUMERIC, 0.2, 0..3)]).after(tokenizing) }
        it { expect('1.').to  fail_with(ParseError).while(tokenizing)              }
        it { expect('.1').to  fail_with(ParseError).while(tokenizing)              }

        context 'leading zeros' do
          it { expect('01.0').to  become([tok(:NUMERIC, 1.0,  0..4)]).after(tokenizing) }
          it { expect('-01.0').to become([tok(:NUMERIC, -1.0, 0..5)]).after(tokenizing) }
        end

        context 'with +|- sign' do
          it { expect('+1.2').to become([tok(:NUMERIC, 1.2, 0..4)]).after(tokenizing)    }
          it { expect('+1.0').to become([tok(:NUMERIC, 1.0, 0..4)]).after(tokenizing)    }
          it { expect('+0.2').to become([tok(:NUMERIC, 0.2, 0..4)]).after(tokenizing)    }

          it { expect('-1.0').to become([tok(:NUMERIC, -1.0, 0..4)]).after(tokenizing)   }
          it { expect('-1.2').to become([tok(:NUMERIC, -1.2, 0..4)]).after(tokenizing)   }
          it { expect('-0.2').to become([tok(:NUMERIC, -0.2, 0..4)]).after(tokenizing)   }
        end

        context 'exponential form' do
          it { expect('1.2e34').to   become([tok(:NUMERIC, 1.2e34,  0..6)]).after(tokenizing) }
          it { expect('1.2e034').to  become([tok(:NUMERIC, 1.2e34,  0..7)]).after(tokenizing) }
          it { expect('1.2e+34').to  become([tok(:NUMERIC, 1.2e34,  0..7)]).after(tokenizing) }
          it { expect('1.2e+034').to become([tok(:NUMERIC, 1.2e34,  0..8)]).after(tokenizing) }
          it { expect('1.2e-34').to  become([tok(:NUMERIC, 1.2e-34, 0..7)]).after(tokenizing) }
          it { expect('1.2e-34').to  become([tok(:NUMERIC, 1.2e-34, 0..7)]).after(tokenizing) }

          it { expect('1.2E34').to   become([tok(:NUMERIC, 1.2e34,  0..6)]).after(tokenizing) }
          it { expect('1.2E034').to  become([tok(:NUMERIC, 1.2e34,  0..7)]).after(tokenizing) }
          it { expect('1.2E+34').to  become([tok(:NUMERIC, 1.2e34,  0..7)]).after(tokenizing) }
          it { expect('1.2E+034').to become([tok(:NUMERIC, 1.2e34,  0..8)]).after(tokenizing) }
          it { expect('1.2E-34').to  become([tok(:NUMERIC, 1.2e-34, 0..7)]).after(tokenizing) }
          it { expect('1.2E-34').to  become([tok(:NUMERIC, 1.2e-34, 0..7)]).after(tokenizing) }
        end
      end
    end

    context 'BOOLEAN' do
      it { expect('v:true').to  become([tok(:BOOLEAN, true,  0..6)]).after(tokenizing) }
      it { expect('v:false').to become([tok(:BOOLEAN, false, 0..7)]).after(tokenizing) }
      it { expect(':true').to   fail_with(ParseError).while(tokenizing) }
      it { expect(':false').to  fail_with(ParseError).while(tokenizing) }
      it { expect('true').to    fail_with(ParseError).while(tokenizing) }
      it { expect('false').to   fail_with(ParseError).while(tokenizing) }
    end

    context 'DICT_RECURSIVE_REF' do
      it { expect(%q|{...}|).to  become([tok(:DICT_RECURSIVE_REF, nil, 0..5)]).after(tokenizing) }
      it { expect(%q|{....}|).to fail_with(ParseError).while(tokenizing) }
      it { expect(%q|{..}|).to   fail_with(ParseError).while(tokenizing) }
      it { expect(%q|{.}|).to    fail_with(ParseError).while(tokenizing) }
    end

    context 'LIST_RECURSIVE_REF' do
      it { expect(%q|[...]|).to  become([tok(:LIST_RECURSIVE_REF, nil, 0..5)]).after(tokenizing) }
      it { expect(%q|[....]|).to fail_with(ParseError).while(tokenizing) }
      it { expect(%q|[..]|).to   fail_with(ParseError).while(tokenizing) }
      it { expect(%q|[.]|).to    fail_with(ParseError).while(tokenizing) }
    end

    context 'FUNCREF' do
      it do
        expect("function('tr')")
          .to become([tok(:FUNCREF, nil,  0..8),
                      tok('(',      '(',  8..9),
                      tok(:STRING,  'tr', 9..13),
                      tok(')',      ')',  13..14)]).after(tokenizing)
      end
    end

    context 'STRING' do
      it { expect("'1'").to    become([tok(:STRING, '1',  0..3)]).after(tokenizing) }
      it { expect('"1"').to    become([tok(:STRING, '1',  0..3)]).after(tokenizing) }
      it { expect(%q|"''"|).to become([tok(:STRING, "''", 0..4)]).after(tokenizing) }
      it { expect(%q|'""'|).to become([tok(:STRING, '""', 0..4)]).after(tokenizing) }

      context 'UTF-8 encoding' do
        let(:encoding) { Encoding::UTF_8 }

        it { expect("'Σ'").to become([tok(:STRING, 'Σ', 0..3)]).after(tokenizing) }
      end
    end

    context 'SEPARATOR' do
      it { expect(':').to become([tok(':', ':', 0..1)]).after(tokenizing) }
      it { expect(',').to become([tok(',', ',', 0..1)]).after(tokenizing) }
      it { expect('{').to become([tok('{', '{', 0..1)]).after(tokenizing) }
      it { expect('}').to become([tok('}', '}', 0..1)]).after(tokenizing) }
      it { expect('(').to become([tok('(', '(', 0..1)]).after(tokenizing) }
      it { expect(')').to become([tok(')', ')', 0..1)]).after(tokenizing) }
      it { expect('[').to become([tok('[', '[', 0..1)]).after(tokenizing) }
      it { expect(']').to become([tok(']', ']', 0..1)]).after(tokenizing) }
    end
  end

  describe '#each_token' do
    let(:str) { '[]' }
    let(:tokens) { [tok('[', '[', 0..1), tok(']', ']', 1..2)] }
    let(:lexer) { VimlValue::Lexer.new(str.dup.force_encoding(encoding)) }
    subject(:enumerator) { lexer.each_token }

    it { expect(enumerator).to be_a(Enumerator) }

    context 'sequential call' do
      it { expect(lexer.each_token.to_a).to eq(lexer.each_token.to_a) }

      it do
        2.times do
          expect { |yield_probe| lexer.each_token(&yield_probe) }
            .to yield_successive_args(*tokens)
        end
      end
    end

    context 'rewind' do
      it { expect(subject.to_a).to        eq(tokens)              }
      it { expect(subject.rewind.to_a).to eq(subject.rewind.to_a) }

      context 'standard enums behaviour correspondence' do
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

    context 'peek' do
      it { expect(subject.peek).to eq(tokens.first) }
      it { expect(subject.peek).to eq(subject.peek) }
    end
  end

  describe '#reset!' do
    let(:str) { '[]' }
    let(:tokens) { [tok('[', '[', 0..1), tok(']', ']', 1..2)] }
    let(:lexer) { VimlValue::Lexer.new(str.dup.force_encoding(encoding)) }

    it do
      expect { lexer.reset! }
        .not_to change { lexer.next_token }
        .from(tokens.first)
    end
  end
end
