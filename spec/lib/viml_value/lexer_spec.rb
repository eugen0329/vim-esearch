# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Lexer, :editor do
  def tokenize(input)
    described_class.new.tap { |l| l.scan_setup(input) }.each.to_a
  end

  def val(ruby_value)
    VimlValue::Lexer::TokenData.new(ruby_value)
  end

  matcher :be_tokenized_as do |expected|
    diffable
    match do |actual|
      @actual = tokenize(actual)
      eq([expected]).matches? @actual
    end

    failure_message do |actual|
      "expected #{actual.inspect} to be tokenized as #{expected.inspect}, got #{@actual.inspect}"
    end
  end

  context 'int' do
    it { expect(tokenize('1')).to    eq([[:NUMBER, val(1)]])    }
    it { expect(tokenize('-1')).to   eq([[:NUMBER, val(-1)]])   }

    it { expect { tokenize '0' }.to raise_error(VimlValue::ParseError) }
    it { expect { tokenize '-0' }.to raise_error(VimlValue::ParseError) }
  end

  context 'float' do
    it { expect(tokenize('1.0')).to eq([[:NUMBER, val(1.0)]])  }
    it { expect(tokenize('1.2')).to eq([[:NUMBER, val(1.2)]])  }
    it { expect(tokenize('0.2')).to eq([[:NUMBER, val(0.2)]])  }
    it { expect(tokenize('-1.0')).to eq([[:NUMBER, val(-1.0)]]) }
    it { expect(tokenize('-1.2')).to eq([[:NUMBER, val(-1.2)]]) }
    it { expect(tokenize('-0.2')).to eq([[:NUMBER, val(-0.2)]]) }

    it { expect { tokenize '1.' }.to raise_error(VimlValue::ParseError) }
    it { expect { tokenize '.1' }.to raise_error(VimlValue::ParseError) }
    it { expect { tokenize '01.0' }.to raise_error(VimlValue::ParseError) }
    it { expect { tokenize '-01.0' }.to raise_error(VimlValue::ParseError) }
  end

  context 'string' do
    it { expect(tokenize("'1'")).to eq([[:STRING, val('1')]]) }
    it { expect(tokenize('"1"')).to eq([[:STRING, val('1')]]) }

    context 'escaping escaping' do
      context 'of surrounding quotes' do
        context 'with backslash' do
          context 'single quote' do
            it { expect { tokenize("'\\''") }.to raise_error(VimlValue::ParseError) }
            it { expect(tokenize("'\\'")).to eq([[:STRING, val('\\')]]) }
            it { expect(tokenize("'\\\\'")).to eq([[:STRING, val('\\\\')]]) }
          end

          context 'double quote' do
            it { expect(tokenize('"\\""')).to eq([[:STRING, val('"')]]) }
            it { expect { tokenize('"\\"') }.to raise_error(VimlValue::ParseError) }
            it { expect(tokenize('"\\\\"')).to eq([[:STRING, val('\\')]]) }
          end
        end

        context 'with duplication' do
          context 'mixing single and double-quoted' do
            it { expect(tokenize(%q("''"))).to eq([[:STRING, val("''")]]) }
            it { expect(tokenize(%q('""'))).to eq([[:STRING, val('""')]]) }
          end

          context 'single-quoted' do
            it { expect(tokenize("''''")).to eq([[:STRING, val("'")]]) }
            it { expect(tokenize("''''''")).to eq([[:STRING, val("''")]]) }
          end

          context 'double-quoted' do
            xit { expect { tokenize('""""') }.to raise_error(VimlValue::ParseError) }
            xit { expect { tokenize('""""""') }.to raise_error(VimlValue::ParseError) }
          end
        end
      end

      context 'special characters' do
        # it { expect(tokenize(%q|"\n"|).to be_parsed_as(%q|\n|) }
        # it { expect(tokenize(%q|"\t"|).to be_parsed_as(%q|\t|) }
      end
    end

  end
end
