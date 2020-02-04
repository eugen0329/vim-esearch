# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#util' do
  include VimlValue::SerializationHelpers

  def split(str)
    data = editor.echo(func('esearch#shell#split', str)).tap(&:inspect)
    return :error if data["error"] != 0

    data['words'].map do |word|
      [word['word'], word['start']..word['end']]
    end
  end

  context 'single word' do
    it { expect(split("ab")).to      eq([['ab', 0..2]])  }
    it { expect(split("ab ")).to     eq([['ab', 0..2]])  }
    it { expect(split(" ab")).to     eq([['ab', 1..3]])  }
  end

  context 'multiple words' do
    it { expect(split("a b")).to  eq([['a', 0..1], ['b',  2..3]]) }
    it { expect(split("a bc")).to eq([['a', 0..1], ['bc', 2..4]]) }
  end

  context 'multibyte' do
    it { expect(split("'Σ'")).to  eq([['Σ', 0..3]]) }
  end

  context 'double quote' do
    it { expect(split('"a b"')).to   eq([['a b', 0..5]]) }
    it { expect(split(' "a b"')).to  eq([['a b', 1..6]]) }
    it { expect(split('"a b" ')).to  eq([['a b', 0..5]]) }
    it { expect(split('"a\\b"')).to eq([['ab', 0..5]]) }
    it { expect(split('"a\\"b"')).to eq([['a"b', 0..6]]) }
    it { expect(split('"a\\\\b"')).to eq([['a\\b', 0..6]]) }
    it { expect(split('a"b"')).to    eq([['ab', 0..4]])  }
    it { expect(split('"a"b')).to    eq([['ab', 0..4]])  }
    it { expect(split('"')).to       eq(:error)          }
    it { expect(split('a"')).to      eq(:error)          }
    it { expect(split('"a')).to      eq(:error)          }

    context 'unescaping anything' do
      it { expect(split('"\\a"')).to   eq([['a', 0..4]]) }
      it { expect(split('"\\&"')).to   eq([['&', 0..4]]) }
      it { expect(split('"\\."')).to   eq([['.', 0..4]]) }
    end
  end

  context 'single quote' do
    it { expect(split("'a b'")).to    eq([['a b', 0..5]]) }
    it { expect(split("'a b' ")).to   eq([['a b', 0..5]]) }
    it { expect(split(" 'a b'")).to   eq([['a b', 1..6]]) }
    it { expect(split("'a\\b'")).to eq([['a\\b', 0..5]]) }
    it { expect(split("'a\\'b'")).to  eq(:error) }
    it { expect(split("'a\\\\b'")).to eq([['a\\\\b', 0..6]]) }
    it { expect(split("a'b'")).to     eq([['ab', 0..4]])  }
    it { expect(split("'a'b")).to     eq([['ab', 0..4]])  }
    it { expect(split("'")).to        eq(:error)          }
    it { expect(split("'a")).to       eq(:error)          }
    it { expect(split("a'")).to       eq(:error)          }
  end

  context 'backslashes' do
    it { expect(split('\\')).to      eq(:error)          }
    it { expect(split("a\\ b")).to   eq([['a b', 0..4]]) }
    it { expect(split("\\ a ")).to   eq([[' a', 0..3]])  }
    it { expect(split("a\\ ")).to    eq([['a ', 0..3]])  }
    it { expect(split("a\\  ")).to   eq([['a ', 0..3]])  }
    it { expect(split("\\\\")).to    eq([['\\', 0..2]])  }

    context 'unescaping anything' do
      it { expect(split("a\\b")).to    eq([['ab', 0..3]]) }
      it { expect(split("ab\\")).to    eq(:error)          }
      it { expect(split("\\ab")).to    eq([['ab', 0..3]]) }

      it { expect(split('\\&')).to   eq([['&', 0..2]]) }
      it { expect(split('\\.')).to   eq([['.', 0..2]]) }
      it { expect(split("\\'")).to   eq([["'", 0..2]]) }
      it { expect(split('\\"')).to   eq([['"', 0..2]]) }
    end
  end
end
