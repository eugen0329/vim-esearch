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

  it { expect('1').to   be_tokenized_as([:NUMBER, val(1)]) }
  it { expect('1.2').to be_tokenized_as([:NUMBER, val(1.2)]) }
end
