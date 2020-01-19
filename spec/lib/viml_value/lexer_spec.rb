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
    it { expect(tokenize '1').to    eq([[:NUMBER, val(1)]])    }
    it { expect(tokenize '-1').to   eq([[:NUMBER, val(-1)]])   }

    it { expect{tokenize '0'}.to raise_error(VimlValue::ParseError) }
    it { expect{tokenize '-0'}.to raise_error(VimlValue::ParseError) }
  end

  context 'float' do
    it { expect(tokenize '1.0').to eq([[:NUMBER, val(1.0)]])  }
    it { expect(tokenize '1.2').to eq([[:NUMBER, val(1.2)]])  }
    it { expect(tokenize '0.2').to eq([[:NUMBER, val(0.2)]])  }
    it { expect(tokenize '-1.0').to eq([[:NUMBER, val(-1.0)]]) }
    it { expect(tokenize '-1.2').to eq([[:NUMBER, val(-1.2)]]) }
    it { expect(tokenize '-0.2').to eq([[:NUMBER, val(-0.2)]]) }

    it { expect{tokenize '1.'}.to raise_error(VimlValue::ParseError) }
    it { expect{tokenize '.1'}.to raise_error(VimlValue::ParseError) }
    it { expect{tokenize '01.0'}.to raise_error(VimlValue::ParseError) }
    it { expect{tokenize '-01.0'}.to raise_error(VimlValue::ParseError) }
  end
end
