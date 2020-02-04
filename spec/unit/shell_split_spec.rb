# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#util' do
  include VimlValue::SerializationHelpers
  include Helpers::FileSystem

  def split(str)
    data = editor.echo(func('esearch#shell#split', str)).tap(&:inspect)
    return :error if data["error"] != 0

    data['words'].map do |word|
      [word['word'], word['start']..word['end']]
    end
  end

  def asterisks_at(str)
    data = editor.echo(func('esearch#shell#split', str)).tap(&:inspect)
    return :error if data["error"] != 0

    data['words'].map { |word| word['asterisks'] }
  end

  context 'asterisks' do

    it { expect(split("\\*ab")).to      eq([['*ab', 0..4]])  }
    it { expect(asterisks_at("*ab")).to      eq([[0]])  }

    it { expect(asterisks_at("ab")).to      eq([[]])  }
    #
    #
    it { expect(asterisks_at("*ab*")).to      eq([[0,3]])  }
    it { expect(asterisks_at("**ab")).to      eq([[0,1]])  }

    it { expect(asterisks_at("*ab")).to      eq([[0]])  }
    it { expect(asterisks_at("*ab")).to      eq([[0]])  }
    it { expect(asterisks_at("a*b")).to      eq([[1]])  }
    it { expect(asterisks_at("ab*")).to      eq([[2]])  }

    it { expect(asterisks_at(" *ab")).to      eq([[1]])  }
    it { expect(asterisks_at(" ab* ")).to      eq([[3]])  }
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

  describe 'esearch#shell#isfile' do
    let(:files) do
      [
        file('a', 'a.ext1'),
        file('a', 'b.ext1'),
        file('a', 'c.ext2'),
        file('a', '*.ext1'),
        file('a', '\\*.ext2'),
      ]
    end
    let(:search_directory) { directory(files, 'globbing_escaped/').persist! }
    before do
      editor.cd! search_directory
    end

    def isfile(str)
      data = editor.echo(func('esearch#shell#isfile', str)).tap(&:inspect)
    end

    def fnameescape(str)
      data = editor.echo(func('esearch#shell#fnamesescape', str)).tap(&:inspect)
    end

    def fnameescape2(str)
      data = editor.echo(func('fnameescape', str)).tap(&:inspect)
    end

    def split_and_escape(str)
      data = editor.echo( func('esearch#shell#fnamesescape', func('esearch#shell#split', str)['words'])).tap(&:inspect)
    end

    it do
      # expect(split_and_escape('\*b')).to eq(['\*b'])
      # expect(split_and_escape('*b')).to eq(['*b'])
      # expect(split_and_escape('b*c')).to eq(['b*c'])

      expect(split_and_escape('*')).to eq(['*'])
      expect(split_and_escape('*a')).to eq(['*a'])
      expect(split_and_escape('a*')).to eq(['a*'])
      expect(split_and_escape('a*bc')).to eq(['a*bc'])
      expect(split_and_escape('a*bcd')).to eq(['a*bcd'])
      expect(split_and_escape('*abc')).to eq(['*abc'])
      expect(split_and_escape('abcd*')).to eq(['abcd*'])
      expect(split_and_escape('*a*')  ).to eq(['*a*'])
      expect(split_and_escape('b*a*') ).to eq(['b*a*'])
      expect(split_and_escape('*b*a') ).to eq(['*b*a'])
      expect(split_and_escape('*b*a*')).to eq(['*b*a*'])

      expect(split_and_escape('\\*')).to eq(['\\*'])
      expect(split_and_escape('\\*a')).to eq(['\\*a'])
      expect(split_and_escape('a\\*')).to eq(['a\\*'])
      expect(split_and_escape('a\\*bc')).to eq(['a\\*bc'])
      expect(split_and_escape('a\\*bcd')).to eq(['a\\*bcd'])
      expect(split_and_escape('\\*abc')).to eq(['\\*abc'])
      expect(split_and_escape('abc\\*')).to eq(['abc\\*'])
      expect(split_and_escape('\\*a\\*')  ).to eq(['\\*a\\*'])
      expect(split_and_escape('b\\*a\\*') ).to eq(['b\\*a\\*'])
      expect(split_and_escape('\\*b\\*a') ).to eq(['\\*b\\*a'])
      expect(split_and_escape('\\*b\\*a\\*')).to eq(['\\*b\\*a\\*'])
    end
  end
end
