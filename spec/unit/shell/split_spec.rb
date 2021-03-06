# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#shell' do
  include VimlValue::SerializationHelpers
  include Helpers::FileSystem
  include Helpers::Shell

  describe '#split' do
    describe 'special' do
      shared_examples 'it tokenizes wildcard' do |c|
        it { expect(tokens_of("#{c}ab")).to     eq([[[1, c], [0, 'ab']]])                      }
        it { expect(tokens_of("a#{c}b")).to     eq([[[0, 'a'], [1, c], [0, 'b']]])             }
        it { expect(tokens_of("ab#{c}")).to     eq([[[0, 'ab'], [1, c]]])                      }
        it { expect(tokens_of("#{c}ab d")).to   eq([[[1, c], [0, 'ab']], [[0, 'd']]])          }
        it { expect(tokens_of("a#{c}b d")).to   eq([[[0, 'a'], [1, c], [0, 'b']], [[0, 'd']]]) }
        it { expect(tokens_of("ab#{c} d")).to   eq([[[0, 'ab'], [1, c]], [[0, 'd']]])          }
        it { expect(tokens_of(" #{c}ab")).to    eq([[[1, c], [0, 'ab']]])                      }
        it { expect(tokens_of(" ab#{c} ")).to   eq([[[0, 'ab'], [1, c]]])                      }
        it { expect(tokens_of("#{c}ab#{c}")).to eq([[[1, c], [0, 'ab'], [1, c]]])              }
        it { expect(tokens_of("#{c}#{c}ab")).to eq([[[1, c], [1, c], [0, 'ab']]])              }
      end

      it { expect(tokens_of('ab cd')).to eq([[[0, 'ab']], [[0, 'cd']]]) }

      describe 'wildcards' do
        include_examples 'it tokenizes wildcard', '?'
        include_examples 'it tokenizes wildcard', '*'
        include_examples 'it tokenizes wildcard', '+'
        include_examples 'it tokenizes wildcard', '@'
        include_examples 'it tokenizes wildcard', '!'
        include_examples 'it tokenizes wildcard', '('
        include_examples 'it tokenizes wildcard', ')'
        include_examples 'it tokenizes wildcard', '|'
        include_examples 'it tokenizes wildcard', '{'
        include_examples 'it tokenizes wildcard', '}'
        include_examples 'it tokenizes wildcard', '['
        include_examples 'it tokenizes wildcard', ']'
        include_examples 'it tokenizes wildcard', '^'
        include_examples 'it tokenizes wildcard', '$'
      end

      describe 'backticks' do
        context 'when trailing' do
          it { expect(tokens_of('`')).to     eq(:error) }
          it { expect(tokens_of('`\``')).to  eq(:error) }
          it { expect(tokens_of('`a\``')).to eq(:error) }
        end

        context 'when toplevel' do
          it { expect(tokens_of('``')).to    eq([[[1, '``']]])  }
          it { expect(tokens_of('`a`')).to   eq([[[1, '`a`']]]) }
        end

        context 'when in strings' do
          it { expect(tokens_of('"`a`"')).to eq([[[1, '`a`']]]) }
          it { expect(tokens_of("'`a`'")).to eq([[[0, '`a`']]]) }
          it { expect(tokens_of('"z`a`b"')).to eq([[[0, 'z'], [1, '`a`'], [0, 'b']]]) }
        end

        context 'when a part of an arg' do
          it { expect(tokens_of('`a`b')).to   eq([[[1, '`a`'], [0, 'b']]])   }
          it { expect(tokens_of('z`a`')).to   eq([[[0, 'z'],   [1, '`a`']]]) }
          it { expect(tokens_of("`a`'b'")).to eq([[[1, '`a`'], [0, 'b']]])   }
          it { expect(tokens_of("'z'`a`")).to eq([[[0, 'z'],   [1, '`a`']]]) }
        end
      end
    end

    describe 'single word' do
      it { expect(split('ab')).to  eq(['ab']) }
      it { expect(split('ab ')).to eq(['ab']) }
      it { expect(split(' ab')).to eq(['ab']) }
    end

    describe 'multiple words' do
      it { expect(split('a b')).to  eq(['a'], ['b',  2..3]) }
      it { expect(split('a bc')).to eq(['a'], ['bc', 2..4]) }
    end

    describe 'multibyte' do
      it { expect(split("'Σ'")).to   eq(['Σ'])              }
      it { expect(split("Σ 'Σ'")).to eq(['Σ'], ['Σ', 2..5]) }
    end

    describe 'double quote' do
      it { expect(split('"a b"')).to    eq(['a b'])  }
      it { expect(split(' "a b"')).to   eq(['a b'])  }
      it { expect(split('"a b" ')).to   eq(['a b'])  }
      it { expect(split('"a\\b"')).to   eq(['ab'])   }
      it { expect(split('"a\\"b"')).to  eq(['a"b'])  }
      it { expect(split('"a\\\\b"')).to eq(['a\\b']) }
      it { expect(split('a"b"')).to     eq(['ab'])   }
      it { expect(split('"a"b')).to     eq(['ab'])   }
      it { expect(split('"')).to        eq(:error)   }
      it { expect(split('a"')).to       eq(:error)   }
      it { expect(split('"a')).to       eq(:error)   }

      describe 'unescaping anything' do
        it { expect(split('"\\a"')).to  eq(['a']) }
        it { expect(split('"\\&"')).to  eq(['&']) }
        it { expect(split('"\\."')).to  eq(['.']) }
      end
    end

    describe 'single quote' do
      it { expect(split("'a b'")).to    eq(['a b'])    }
      it { expect(split("'a b' ")).to   eq(['a b'])    }
      it { expect(split(" 'a b'")).to   eq(['a b'])    }
      it { expect(split("'a\\b'")).to   eq(['a\\b'])   }
      it { expect(split("'a\\'b'")).to  eq(:error)     }
      it { expect(split("'a\\\\b'")).to eq(['a\\\\b']) }
      it { expect(split("a'b'")).to     eq(['ab'])     }
      it { expect(split("'a'b")).to     eq(['ab'])     }
      it { expect(split("'")).to        eq(:error)     }
      it { expect(split("'a")).to       eq(:error)     }
      it { expect(split("a'")).to       eq(:error)     }
    end

    describe 'backslashes' do
      it { expect(split('\\')).to      eq(:error) }
      it { expect(split('a\\ b')).to   eq(['a b']) }
      it { expect(split('\\ a ')).to   eq([' a'])  }
      it { expect(split('a\\ ')).to    eq(['a '])  }
      it { expect(split('a\\  ')).to   eq(['a '])  }
      it { expect(split('\\\\')).to    eq(['\\'])  }
      it { expect(split('\\`')).to     eq(['`'])   }

      describe 'globbing' do
        it { expect(split('\\*ab')).to eq(['*ab']) }
      end

      describe 'unescaping anything' do
        it { expect(split('a\\b')).to eq(['ab']) }
        it { expect(split('ab\\')).to eq(:error) }
        it { expect(split('\\ab')).to eq(['ab']) }
        it { expect(split('\\&')).to  eq(['&'])  }
        it { expect(split('\\.')).to  eq(['.'])  }
        it { expect(split("\\'")).to  eq(["'"])  }
        it { expect(split('\\"')).to  eq(['"'])  }
      end
    end
  end
end
