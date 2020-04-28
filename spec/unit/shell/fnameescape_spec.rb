# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#shell' do
  include VimlValue::SerializationHelpers
  include Helpers::FileSystem
  include Helpers::Shell

  describe '#fnameescape' do
    # It Doesn't make a lot of sense to test it separately from #split due to
    # possible false positives and much more complicated setup. Thus
    # fnameescape(split(...)) is tested here.

    context 'when metachars' do
      shared_examples 'prevents special from escaping' do |c|
        it { expect(split_and_escape("#{c}b")).to          eq(["#{c}b"])          }
        it { expect(split_and_escape(c.to_s)).to           eq([c.to_s])           }
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
        include_examples 'prevents special from escaping', c
        include_examples 'prevents special from double escaping', c
      end

      include_examples 'handles escaping of shell special', '?'
      include_examples 'handles escaping of shell special', '*'
      include_examples 'handles escaping of shell special', '!'
      include_examples 'handles escaping of shell special', '|'

      include_examples 'handles escaping of shell special', '^'
      include_examples 'handles escaping of shell special', '$'
      include_examples 'handles escaping of shell special', '['
      include_examples 'handles escaping of shell special', ']'
      include_examples 'handles escaping of shell special', '@'
      include_examples 'handles escaping of shell special', '('
      include_examples 'handles escaping of shell special', ')'
      include_examples 'handles escaping of shell special', '{'
      include_examples 'handles escaping of shell special', '}'
      include_examples 'handles escaping of shell special', '+'
    end

    context 'when special only when leading' do
      # Based on :h fnameescape() and src/vim.h
      it { expect(split_and_escape('-')).to   eq(['\-'])  }
      it { expect(split_and_escape('-a')).to  eq(['-a'])  }
      it { expect(split_and_escape('a-')).to  eq(['a-'])  }
      it { expect(split_and_escape('>')).to   eq(['\>'])  }
      it { expect(split_and_escape('>a')).to  eq(['\>a']) }
      it { expect(split_and_escape('a>')).to  eq(['a>'])  }
      it { expect(split_and_escape('\+')).to  eq(['\+'])  }
      it { expect(split_and_escape('\+a')).to eq(['\+a']) }
      it { expect(split_and_escape('a\+')).to eq(['a\+']) }
    end
  end
end
