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
    paths, metadata, error = editor.echo(func('esearch#shell#split', str))
    return :error if error != 0

    metadata.map { |word| word['wildcards'] }
  end

  context 'wildcards' do
    it { expect(wildcards_at('*ab')).to   eq([[0]])    }
    it { expect(wildcards_at('ab')).to    eq([[]])     }
    it { expect(wildcards_at('*ab*')).to  eq([[0, 3]]) }
    it { expect(wildcards_at('**ab')).to  eq([[0, 1]]) }
    it { expect(wildcards_at('*ab')).to   eq([[0]])    }
    it { expect(wildcards_at('*ab')).to   eq([[0]])    }
    it { expect(wildcards_at('a*b')).to   eq([[1]])    }
    it { expect(wildcards_at('ab*')).to   eq([[2]])    }
    it { expect(wildcards_at(' *ab')).to  eq([[1]])    }
    it { expect(wildcards_at(' ab* ')).to eq([[3]])    }
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

  describe 'esearch#shell#isfile' do
    let(:files) do
      [
        file('a', 'a.ext1'),
        file('a', 'b.ext1'),
        file('a', 'c.ext2'),
        file('a', '*.ext1'),
        file('a', '\\*.ext2')
      ]
    end
    let(:search_directory) { directory(files, 'globbing_escaped/').persist! }

    def split_and_escape(str)
      paths, metadata, error = editor.echo(func('esearch#shell#split', str))
      return :error if error != 0
      paths.zip(metadata).map do |path, meta|
        editor.echo(func('esearch#shell#fnameescape', path, meta))
      end
    end

    context 'not escaped wildcards' do
      it { expect(split_and_escape('*b')).to    eq(['*b'])   }
      it { expect(split_and_escape('b*c')).to   eq(['b*c'])  }
      it { expect(split_and_escape('*')).to     eq(['*'])    }
      it { expect(split_and_escape('*a')).to    eq(['*a'])   }
      it { expect(split_and_escape('a*')).to    eq(['a*'])   }
      it { expect(split_and_escape('a*bc')).to  eq(['a*bc']) }
      it { expect(split_and_escape('a*bcd')).to eq(['a*bcd'])}
      it { expect(split_and_escape('*abc')).to  eq(['*abc']) }
      it { expect(split_and_escape('abcd*')).to eq(['abcd*'])}
      it { expect(split_and_escape('*a*')).to   eq(['*a*'])  }
      it { expect(split_and_escape('b*a*')).to  eq(['b*a*']) }
      it { expect(split_and_escape('*b*a')).to  eq(['*b*a']) }
      it { expect(split_and_escape('*b*a*')).to eq(['*b*a*'])}
    end

    context 'escaped wildcards' do
      it { expect(split_and_escape('\\*')).to         eq(['\\*'])         }
      it { expect(split_and_escape('\\*a')).to        eq(['\\*a'])        }
      it { expect(split_and_escape('a\\*')).to        eq(['a\\*'])        }
      it { expect(split_and_escape('a\\*bc')).to      eq(['a\\*bc'])      }
      it { expect(split_and_escape('a\\*bcd')).to     eq(['a\\*bcd'])     }
      it { expect(split_and_escape('\\*abc')).to      eq(['\\*abc'])      }
      it { expect(split_and_escape('abc\\*')).to      eq(['abc\\*'])      }
      it { expect(split_and_escape('\\*a\\*')).to     eq(['\\*a\\*'])     }
      it { expect(split_and_escape('b\\*a\\*')).to    eq(['b\\*a\\*'])    }
      it { expect(split_and_escape('\\*b\\*a')).to    eq(['\\*b\\*a'])    }
      it { expect(split_and_escape('\\*b\\*a\\*')).to eq(['\\*b\\*a\\*']) }

      it { expect(split_and_escape('""a\\*')).to      eq(['a\\*'])        }
      it { expect(split_and_escape('""a*a')).to       eq(['a*a'])         }
      it { expect(split_and_escape('""a\\*')).to      eq(['a\\*'])        }
      it { expect(split_and_escape('""a*a')).to       eq(['a*a'])         }

      it { expect(split_and_escape('""a*a\\')).to     eq(:error)          }
      it { expect(split_and_escape('""a*a"')).to      eq(:error)          }
    end
  end
end
