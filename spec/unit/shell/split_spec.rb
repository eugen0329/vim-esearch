# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#shell' do
  include VimlValue::SerializationHelpers
  include Helpers::FileSystem
  include Helpers::Shell

  describe '#split' do
    describe 'special' do
      shared_examples 'it detects wildcars location' do |c|
        it { expect(metachars_at("#{c}ab")).to     eq([[0]])    }
        it { expect(metachars_at("#{c}ab#{c}")).to eq([[0, 3]]) }
        it { expect(metachars_at("#{c}#{c}ab")).to eq([[0, 1]]) }
        it { expect(metachars_at("#{c}ab")).to     eq([[0]])    }
        it { expect(metachars_at("a#{c}b")).to     eq([[1]])    }
        it { expect(metachars_at("ab#{c}")).to     eq([[2]])    }
        it { expect(metachars_at(" #{c}ab")).to    eq([[0]])    }
        it { expect(metachars_at(" ab#{c} ")).to   eq([[2]])    }
      end

      include_examples 'it detects wildcars location', '?'
      include_examples 'it detects wildcars location', '*'
      include_examples 'it detects wildcars location', '+'
      include_examples 'it detects wildcars location', '@'
      include_examples 'it detects wildcars location', '!'
      include_examples 'it detects wildcars location', '('
      include_examples 'it detects wildcars location', ')'
      include_examples 'it detects wildcars location', '|'
      include_examples 'it detects wildcars location', '{'
      include_examples 'it detects wildcars location', '}'
      include_examples 'it detects wildcars location', '['
      include_examples 'it detects wildcars location', ']'
      include_examples 'it detects wildcars location', '^'
      include_examples 'it detects wildcars location', '$'

      it { expect(metachars_at('ab')).to eq([[]]) }
    end

    describe 'single word' do
      it { expect(split('ab')).to  eq([['ab', 0..2]]) }
      it { expect(split('ab ')).to eq([['ab', 0..2]]) }
      it { expect(split(' ab')).to eq([['ab', 1..3]]) }
    end

    describe 'multiple words' do
      it { expect(split('a b')).to  eq([['a', 0..1], ['b',  2..3]]) }
      it { expect(split('a bc')).to eq([['a', 0..1], ['bc', 2..4]]) }
    end

    describe 'multibyte' do
      it { expect(split("'Σ'")).to  eq([['Σ', 0..3]]) }
    end

    describe 'double quote' do
      it { expect(split('"a b"')).to    eq([['a b', 0..5]])  }
      it { expect(split(' "a b"')).to   eq([['a b', 1..6]])  }
      it { expect(split('"a b" ')).to   eq([['a b', 0..5]])  }
      it { expect(split('"a\\b"')).to   eq([['ab', 0..5]])   }
      it { expect(split('"a\\"b"')).to  eq([['a"b', 0..6]])  }
      it { expect(split('"a\\\\b"')).to eq([['a\\b', 0..6]]) }
      it { expect(split('a"b"')).to     eq([['ab', 0..4]])   }
      it { expect(split('"a"b')).to     eq([['ab', 0..4]])   }
      it { expect(split('"')).to        eq(:error)           }
      it { expect(split('a"')).to       eq(:error)           }
      it { expect(split('"a')).to       eq(:error)           }

      describe 'unescaping anything' do
        it { expect(split('"\\a"')).to  eq([['a', 0..4]])    }
        it { expect(split('"\\&"')).to  eq([['&', 0..4]])    }
        it { expect(split('"\\."')).to  eq([['.', 0..4]])    }
      end
    end

    describe 'single quote' do
      it { expect(split("'a b'")).to    eq([['a b', 0..5]])    }
      it { expect(split("'a b' ")).to   eq([['a b', 0..5]])    }
      it { expect(split(" 'a b'")).to   eq([['a b', 1..6]])    }
      it { expect(split("'a\\b'")).to   eq([['a\\b', 0..5]])   }
      it { expect(split("'a\\'b'")).to  eq(:error)             }
      it { expect(split("'a\\\\b'")).to eq([['a\\\\b', 0..6]]) }
      it { expect(split("a'b'")).to     eq([['ab', 0..4]])     }
      it { expect(split("'a'b")).to     eq([['ab', 0..4]])     }
      it { expect(split("'")).to        eq(:error)             }
      it { expect(split("'a")).to       eq(:error)             }
      it { expect(split("a'")).to       eq(:error)             }
    end

    describe 'eval' do
      describe 'backticks' do
        it { expect(split('`')).to     eq(:error)          }
        it { expect(split('`\``')).to  eq(:error)          }
        it { expect(split('`a\``')).to eq(:error)          }
        it { expect(split('``')).to    eq([['``',  0..2]]) }
        it { expect(split('`a`')).to   eq([['`a`', 0..3]]) }
        it { expect(split('"`a`"')).to eq([['`a`', 0..5]]) }
        it { expect(split("'`a`'")).to eq([['`a`', 0..5]]) }
      end
    end

    describe 'backslashes' do
      it { expect(split('\\')).to      eq(:error)          }
      it { expect(split('a\\ b')).to   eq([['a b', 0..4]]) }
      it { expect(split('\\ a ')).to   eq([[' a', 0..3]])  }
      it { expect(split('a\\ ')).to    eq([['a ', 0..3]])  }
      it { expect(split('a\\  ')).to   eq([['a ', 0..3]])  }
      it { expect(split('\\\\')).to    eq([['\\', 0..2]])  }
      it { expect(split('\\`')).to     eq([['`', 0..2]])   }

      describe 'globbing' do
        it { expect(split('\\*ab')).to eq([['*ab', 0..4]]) }
      end

      describe 'unescaping anything' do
        it { expect(split('a\\b')).to eq([['ab', 0..3]]) }
        it { expect(split('ab\\')).to eq(:error)         }
        it { expect(split('\\ab')).to eq([['ab', 0..3]]) }
        it { expect(split('\\&')).to  eq([['&', 0..2]])  }
        it { expect(split('\\.')).to  eq([['.', 0..2]])  }
        it { expect(split("\\'")).to  eq([["'", 0..2]])  }
        it { expect(split('\\"')).to  eq([['"', 0..2]])  }
      end
    end
  end
end
