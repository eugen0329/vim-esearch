# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Parser do
  def parse(input)
    parsed = described_class
      .new(VimlValue::Lexer.new, input)
      .parse

    VimlValue::ToRuby.new.accept(parsed)
  end

  shared_examples 'it tokenizes vim internal literal' do |name, type, ruby_value|
    it { expect(parse("v:#{name}")).to         eq(ruby_value) }

    it { expect { parse "a:#{name}" }.to raise_error(VimlValue::ParseError) }
    it { expect { parse "l:#{name}" }.to raise_error(VimlValue::ParseError) }
    it { expect { parse "w:#{name}" }.to raise_error(VimlValue::ParseError) }
    it { expect { parse "b:#{name}" }.to raise_error(VimlValue::ParseError) }
    it { expect { parse "g:#{name}" }.to raise_error(VimlValue::ParseError) }
    it { expect { parse "s:#{name}" }.to raise_error(VimlValue::ParseError) }
    it { expect { parse name.to_s }.to raise_error(VimlValue::ParseError) }
  end

  context 'int' do
    it { expect(parse('1')).to    eq(1)    }
    it { expect(parse('-1')).to   eq(-1)   }

    it { expect { parse '0' }.to raise_error(VimlValue::ParseError) }
    it { expect { parse '-0' }.to raise_error(VimlValue::ParseError) }
  end

  context 'bool' do
    it_behaves_like 'it tokenizes vim internal literal', 'true',  :BOOL, true
    it_behaves_like 'it tokenizes vim internal literal', 'false', :BOOL, false
  end

  context 'null' do
    it_behaves_like 'it tokenizes vim internal literal', 'null', :NULL, nil
  end

  context 'float' do
    it { expect(parse('1.0')).to eq(1.0)  }
    it { expect(parse('1.2')).to eq(1.2)  }
    it { expect(parse('0.2')).to eq(0.2)  }
    it { expect(parse('-1.0')).to eq(-1.0) }
    it { expect(parse('-1.2')).to eq(-1.2) }
    it { expect(parse('-0.2')).to eq(-0.2) }

    it { expect { parse '1.' }.to raise_error(VimlValue::ParseError) }
    it { expect { parse '.1' }.to raise_error(VimlValue::ParseError) }
    it { expect { parse '01.0' }.to raise_error(VimlValue::ParseError) }
    it { expect { parse '-01.0' }.to raise_error(VimlValue::ParseError) }
  end

  context 'string' do
    it { expect(parse("'1'")).to eq('1') }
    it { expect(parse('"1"')).to eq('1') }

    context 'escaping escaping' do
      context 'of surrounding quotes' do
        context 'with backslash' do
          context 'single quote' do
            it { expect { parse("'\\''") }.to raise_error(VimlValue::ParseError) }
            it { expect(parse("'\\'")).to eq('\\') }
            it { expect(parse("'\\\\'")).to eq('\\\\') }
          end

          context 'double quote' do
            it { expect(parse('"\\""')).to eq('"') }
            it { expect { parse('"\\"') }.to raise_error(VimlValue::ParseError) }
            it { expect(parse('"\\\\"')).to eq('\\') }
          end
        end

        context 'with duplication' do
          context 'mixing single and double-quoted' do
            it { expect(parse(%q("''"))).to eq("''") }
            it { expect(parse(%q('""'))).to eq('""') }
          end

          context 'single-quoted' do
            it { expect(parse("''''")).to eq("'") }
            it { expect(parse("''''''")).to eq("''") }
          end

          context 'double-quoted' do
            xit { expect { parse('""""') }.to raise_error(VimlValue::ParseError) }
            xit { expect { parse('""""""') }.to raise_error(VimlValue::ParseError) }
          end
        end
      end

      context 'special characters' do
        # it { expect(parse(%q|"\n"|).to be_parsed_as(%q|\n|) }
        # it { expect(parse(%q|"\t"|).to be_parsed_as(%q|\t|) }
      end
    end
  end
end
