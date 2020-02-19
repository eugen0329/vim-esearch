# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#util' do
  include VimlValue::SerializationHelpers
  include Helpers::FileSystem

  def split(str)
    paths, metadata, error = editor.echo(func('esearch#shell#split', str))
    return :error if error != 0

    paths.zip(metadata).map do |path, m|
      [path, m['start']..m['end']]
    end
  end

  def wildcards_at(str)
    _paths, metadata, error = editor.echo(func('esearch#shell#split', str))
    return :error if error != 0

    metadata.map { |word| word['wildcards'] }
  end

  context 'special' do
    shared_examples 'it detects wildcars location' do |c|
      it { expect(wildcards_at("ab")).to         eq([[]])     }
      it { expect(wildcards_at("#{c}ab")).to     eq([[0]])    }
      it { expect(wildcards_at("#{c}ab#{c}")).to eq([[0, 3]]) }
      it { expect(wildcards_at("#{c}#{c}ab")).to eq([[0, 1]]) }
      it { expect(wildcards_at("#{c}ab")).to     eq([[0]])    }
      it { expect(wildcards_at("a#{c}b")).to     eq([[1]])    }
      it { expect(wildcards_at("ab#{c}")).to     eq([[2]])    }
      it { expect(wildcards_at(" #{c}ab")).to    eq([[0]])    }
      it { expect(wildcards_at(" ab#{c} ")).to   eq([[2]])    }
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
  end

  context 'single word' do
    it { expect(split('ab')).to  eq([['ab', 0..2]]) }
    it { expect(split('ab ')).to eq([['ab', 0..2]]) }
    it { expect(split(' ab')).to eq([['ab', 1..3]]) }
  end

  context 'multiple words' do
    it { expect(split('a b')).to  eq([['a', 0..1], ['b',  2..3]]) }
    it { expect(split('a bc')).to eq([['a', 0..1], ['bc', 2..4]]) }
  end

  context 'multibyte' do
    it { expect(split("'Σ'")).to  eq([['Σ', 0..3]]) }
  end

  context 'double quote' do
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

    context 'unescaping anything' do
      it { expect(split('"\\a"')).to  eq([['a', 0..4]])    }
      it { expect(split('"\\&"')).to  eq([['&', 0..4]])    }
      it { expect(split('"\\."')).to  eq([['.', 0..4]])    }
    end
  end

  context 'single quote' do
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

  context 'backslashes' do
    it { expect(split('\\')).to      eq(:error)          }
    it { expect(split('a\\ b')).to   eq([['a b', 0..4]]) }
    it { expect(split('\\ a ')).to   eq([[' a', 0..3]])  }
    it { expect(split('a\\ ')).to    eq([['a ', 0..3]])  }
    it { expect(split('a\\  ')).to   eq([['a ', 0..3]])  }
    it { expect(split('\\\\')).to    eq([['\\', 0..2]])  }

    context 'globbing' do
      it { expect(split('\\*ab')).to eq([['*ab', 0..4]]) }
    end

    context 'unescaping anything' do
      it { expect(split('a\\b')).to eq([['ab', 0..3]]) }
      it { expect(split('ab\\')).to eq(:error)         }
      it { expect(split('\\ab')).to eq([['ab', 0..3]]) }
      it { expect(split('\\&')).to  eq([['&', 0..2]])  }
      it { expect(split('\\.')).to  eq([['.', 0..2]])  }
      it { expect(split("\\'")).to  eq([["'", 0..2]])  }
      it { expect(split('\\"')).to  eq([['"', 0..2]])  }
    end
  end

  describe 'esearch#shell#fnameescape' do
    def split_and_escape(str)
      paths, metadata, error = editor.echo(func('esearch#shell#split', str))
      return :error if error != 0

      paths.zip(metadata).map do |path, meta|
        editor.echo(func('esearch#shell#fnameescape', path, meta))
      end
    end

    shared_examples 'prevents special from escaping' do |c|
      it { expect(split_and_escape("#{c}b")).to          eq(["#{c}b"])          }
      it { expect(split_and_escape("#{c}")).to           eq(["#{c}"])           }
      it { expect(split_and_escape("#{c}a")).to          eq(["#{c}a"])          }
      it { expect(split_and_escape("#{c}abc")).to        eq(["#{c}abc"])        }
      it { expect(split_and_escape("#{c}a#{c}")).to      eq(["#{c}a#{c}"])      }
      it { expect(split_and_escape("#{c}b#{c}a")).to     eq(["#{c}b#{c}a"])     }
      it { expect(split_and_escape("#{c}b#{c}a#{c}")).to eq(["#{c}b#{c}a#{c}"]) }

      it { expect(split_and_escape("b#{c}c")).to         eq(["b#{c}c"])         }
      it { expect(split_and_escape("a#{c}")).to          eq(["a#{c}"])          }
      it { expect(split_and_escape("a#{c}bc")).to        eq(["a#{c}bc"])        }
      it { expect(split_and_escape("a#{c}bcd")).to       eq(["a#{c}bcd"])       }
      it { expect(split_and_escape("abcd#{c}")).to       eq(["abcd#{c}"])       }
      it { expect(split_and_escape("b#{c}a#{c}")).to     eq(["b#{c}a#{c}"])     }
    end

    shared_examples 'prevents only leading special from double escaping' do |c|
      # TODO
      it { expect(split_and_escape("\\#{c}")).to        eq(["\\#{c}"])          }
      it { expect(split_and_escape("\\#{c}a")).to       eq(["\\#{c}a"])         }
      it { expect(split_and_escape("\\#{c}a\\#{c}")).to eq(["\\#{c}a\\#{c}"]) }
    end

    shared_examples 'prevents special from double escaping' do |c|
      it { expect(split_and_escape("\\#{c}")).to               eq(["\\#{c}"])               }
      it { expect(split_and_escape("\\#{c}a")).to              eq(["\\#{c}a"])              }
      it { expect(split_and_escape("\\#{c}abc")).to            eq(["\\#{c}abc"])            }
      it { expect(split_and_escape("\\#{c}a\\#{c}")).to        eq(["\\#{c}a\\#{c}"])        }
      it { expect(split_and_escape("\\#{c}b\\#{c}a")).to       eq(["\\#{c}b\\#{c}a"])       }
      it { expect(split_and_escape("\\#{c}b\\#{c}a\\#{c}")).to eq(["\\#{c}b\\#{c}a\\#{c}"]) }

      it { expect(split_and_escape("a\\#{c}")).to              eq(["a\\#{c}"])              }
      it { expect(split_and_escape("a\\#{c}bc")).to            eq(["a\\#{c}bc"])            }
      it { expect(split_and_escape("a\\#{c}bcd")).to           eq(["a\\#{c}bcd"])           }
      it { expect(split_and_escape("abc\\#{c}")).to            eq(["abc\\#{c}"])            }
      it { expect(split_and_escape("b\\#{c}a\\#{c}")).to       eq(["b\\#{c}a\\#{c}"])       }

      it { expect(split_and_escape("''a\\#{c}")).to            eq(["a\\#{c}"])              }
      it { expect(split_and_escape("''a#{c}a")).to             eq(["a#{c}a"])               }
      it { expect(split_and_escape("''a\\#{c}")).to            eq(["a\\#{c}"])              }
      it { expect(split_and_escape("''a#{c}a")).to             eq(["a#{c}a"])               }

      it { expect(split_and_escape("''a#{c}a\\")).to           eq(:error)                   }
      it { expect(split_and_escape("''a#{c}a'")).to            eq(:error)                   }
    end

    shared_examples 'handles escaping of shell special' do |c|
      include_examples 'prevents special from escaping',  c
      include_examples 'prevents special from double escaping', c
    end

    context 'builtin fnameescape function quirks' do
      let(:argument) { '+[]?*+@!()|{}' }
      let(:returned) { '\+\[]\?\*+@\!()\|\{}' }

      it do
        expect(editor.echo(func('fnameescape', argument))).to eq(returned)
      end
    end

    include_examples 'handles escaping of shell special', '?'
    include_examples 'handles escaping of shell special', '*'
    include_examples 'handles escaping of shell special', '!'
    include_examples 'handles escaping of shell special', '|'
    include_examples 'handles escaping of shell special', '{'
    include_examples 'handles escaping of shell special', '['

    include_examples 'handles escaping of shell special', '^'
    include_examples 'handles escaping of shell special', ']'
    include_examples 'handles escaping of shell special', '@'
    include_examples 'handles escaping of shell special', '('
    include_examples 'handles escaping of shell special', ')'
    include_examples 'handles escaping of shell special', '}'

    # TODO investigate + behaviour
    include_examples 'prevents special from escaping',  '+'
    # include_examples 'prevents special from double escaping', '+'
  end
end
