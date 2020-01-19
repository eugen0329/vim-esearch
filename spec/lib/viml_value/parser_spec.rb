# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Parser do
  def parse(input)
    parsed = described_class
             .new(VimlValue::Lexer.new, input)
             .parse

    VimlValue::ToRuby.new.accept(parsed)
  end

  def function(name)
    VimlValue::ToRuby::Funcref.new(name)
  end
  def self.function(name)
    VimlValue::ToRuby::Funcref.new(name)
  end

  shared_examples 'wrapped value' do |wrap, wrap_result|
    shared_examples 'it parses vim internal literal' do |name, ruby_value|
      it { expect(parse(wrap.call("v:#{name}"))).to eq(wrap_result.call(ruby_value)) }

      it { expect { parse(wrap.call("a:#{name}")) }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call("l:#{name}")) }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call("w:#{name}")) }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call("b:#{name}")) }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call("g:#{name}")) }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call("s:#{name}")) }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call(name.to_s))   }.to raise_error(VimlValue::ParseError) }
    end

    context 'int' do
      it { expect(parse(wrap.call('1'))).to  eq(wrap_result.call(1))  }
      it { expect(parse(wrap.call('-1'))).to eq(wrap_result.call(-1)) }

      it { expect { parse(wrap.call('0')) }.to  raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call('-0')) }.to raise_error(VimlValue::ParseError) }
    end

    context 'bool' do
      it_behaves_like 'it parses vim internal literal', 'true',  true
      it_behaves_like 'it parses vim internal literal', 'false', false
    end

    context 'null' do
      it_behaves_like 'it parses vim internal literal', 'null', nil
    end

    context 'float' do
      it { expect(parse(wrap.call('1.0'))).to  eq(wrap_result.call(1.0))  }
      it { expect(parse(wrap.call('1.2'))).to  eq(wrap_result.call(1.2))  }
      it { expect(parse(wrap.call('0.2'))).to  eq(wrap_result.call(0.2))  }
      it { expect(parse(wrap.call('-1.0'))).to eq(wrap_result.call(-1.0)) }
      it { expect(parse(wrap.call('-1.2'))).to eq(wrap_result.call(-1.2)) }
      it { expect(parse(wrap.call('-0.2'))).to eq(wrap_result.call(-0.2)) }

      it { expect { parse(wrap.call('1.'))    }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call('.1'))    }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call('01.0'))  }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call('-01.0')) }.to raise_error(VimlValue::ParseError) }
    end

    context 'function references' do
      it { expect(parse(wrap.call(%q|function('tr')|))).to eq(wrap_result.call(function('tr')))  }
      it { expect(parse(wrap.call(%q|function("tr")|))).to eq(wrap_result.call(function('tr')))  }

      it { expect { parse(wrap.call(%q|function|))        }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call(%q|function()|))      }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call(%q|function(1)|))     }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call(%q|function({})|))    }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call(%q|function([])|))    }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call(%q|function("tr"|))   }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call(%q|function"tr")|))   }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(wrap.call(%q|function "tr"|))   }.to raise_error(VimlValue::ParseError) }
    end

    context 'string' do
      it { expect(parse(wrap.call("'1'"))).to eq(wrap_result.call('1')) }
      it { expect(parse(wrap.call('"1"'))).to eq(wrap_result.call('1')) }

      # rubocop:disable Layout/SpaceInsideParens
      context 'escaping' do
        context 'of surrounding quotes' do
          context 'with backslash' do
            context 'single quote' do
              it { expect { parse(wrap.call("'\\''"))  }.to raise_error(VimlValue::ParseError) }
              it { expect(  parse(wrap.call("'\\'"))   ).to eq(wrap_result.call('\\')) }
              it { expect(  parse(wrap.call("'\\\\'")) ).to eq(wrap_result.call('\\\\')) }
            end

            context 'double quote' do
              it { expect(  parse(wrap.call('"\\""')) ).to eq(wrap_result.call('"')) }
              it { expect { parse(wrap.call('"\\"'))  }.to raise_error(VimlValue::ParseError) }
              it { expect(  parse(wrap.call('"\\\\"'))).to eq(wrap_result.call('\\')) }
            end
          end

          context 'with duplication' do
            context 'single-quoted' do
              it { expect(parse(wrap.call("''''"))).to eq(wrap_result.call("'")) }
              it { expect(parse(wrap.call("''''''"))).to eq(wrap_result.call("''")) }
            end

            context 'double-quoted' do
              it { expect { parse(wrap.call('""""')) }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call('""""""')) }.to raise_error(VimlValue::ParseError) }
            end

            context 'mixing single and double-quoted' do
              # have to be tested in terms of integration as some quotes escaping
              # is valid in terms of tokenization, but invalid as a viml value
              it { expect(parse(wrap.call(%q|"''"|))).to eq(wrap_result.call("''")) }
              it { expect(parse(wrap.call(%q|'""'|))).to eq(wrap_result.call('""')) }

              # A bit verbose, but helps to understand how tricky escaping works
              # in vim and ensure that everything works properly
              it { expect { parse(wrap.call('\\"""""')) }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call('"\\""""')) }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call('""\\"""')) }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call('"""\\""')) }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call('""""\\"')) }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call("\\'''''")) }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call("'\\''''")) }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call("''\\'''")) }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call("'''\\''")) }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call("''''\\'")) }.to raise_error(VimlValue::ParseError) }

              it { expect { parse(wrap.call('\\""""'))  }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call('"\\"""'))  }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call('""\\""'))  }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call('"""\\"'))  }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call('""""\\'))  }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call("\\''''"))  }.to raise_error(VimlValue::ParseError) }
              it { expect(  parse(wrap.call("'\\'''"))  ).to eq(wrap_result.call("\\'")) }
              it { expect { parse(wrap.call("''\\''"))  }.to raise_error(VimlValue::ParseError) }
              it { expect(  parse(wrap.call("'''\\'"))  ).to eq(wrap_result.call("'\\")) }
              it { expect { parse(wrap.call("''''\\"))  }.to raise_error(VimlValue::ParseError) }

              it { expect { parse(wrap.call('\\"""'))   }.to raise_error(VimlValue::ParseError) }
              it { expect(  parse(wrap.call('"\\""'))   ).to eq(wrap_result.call('"')) }
              it { expect { parse(wrap.call('""\\"'))   }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call('"""\\'))   }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call("\\'''"))   }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call("'\\''"))   }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call("''\\'"))   }.to raise_error(VimlValue::ParseError) }
              it { expect { parse(wrap.call("'''\\"))   }.to raise_error(VimlValue::ParseError) }

              it { expect(parse(wrap.call(%q|"\\'"|))).to eq(wrap_result.call("'")) }
              it { expect(parse(wrap.call("'\\'''"))).to  eq(wrap_result.call("\\'")) }
              it { expect(parse(wrap.call("'''\\'"))).to  eq(wrap_result.call("'\\")) }
            end
          end
        end
        # rubocop:enable Layout/SpaceInsideParens

        context 'special characters' do
          # it { expect(parse(wrap.call %q|"\n"|).to eq(wrap_result.call %q|\n|) }
          # it { expect(parse(wrap.call %q|"\t"|).to eq(wrap_result.call %q|\t|) }
        end
      end
    end
  end

  context 'toplevel' do
    include_examples 'wrapped value',
      ->(given_string)    { given_string },
      ->(expected_object) { expected_object }
  end

  context 'inside list' do
    include_examples 'wrapped value',
      ->(given_string)    { "[#{given_string}]" },
      ->(expected_object) { [expected_object] }

    it { expect { parse('1,2') }.to raise_error(VimlValue::ParseError) }

    context 'trailing comma' do
      it { expect(parse('[1,]')).to eq([1]) }
      it { expect { parse('[1,,]') }.to raise_error(VimlValue::ParseError) }
      it { expect { parse('[,]')   }.to raise_error(VimlValue::ParseError) }
    end
  end

  context 'inside dict' do
    include_examples 'wrapped value',
      ->(given_string)    { "{'key': #{given_string}}" },
      ->(expected_object) { {'key' => expected_object} }

    context 'trailing comma' do
      it { expect(parse('{"key": 1,}')).to eq('key' => 1) }
      it { expect { parse('{"key": 1,,]') }.to raise_error(VimlValue::ParseError) }
      it { expect { parse('{"key":,}')    }.to raise_error(VimlValue::ParseError) }
      it { expect { parse('{,}')          }.to raise_error(VimlValue::ParseError) }
    end

    context 'incorrect pairs' do
      it { expect { parse(%q|{1}|)      }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(%q|{1: 1}|)   }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(%q|{1: '1'}|) }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(%q|{''}|)     }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(%q|{""}|)     }.to raise_error(VimlValue::ParseError) }
    end
  end

  context 'inside deeply nested structure' do
    include_examples 'wrapped value',
      ->(given_string)    { %Q|[1,[ { 'key' : #{given_string} } , 2, function('Fn'), ["3"]], 4]| },
      ->(expected_object) { [1, [{'key' => expected_object}, 2, function('Fn'), ['3']], 4] }
  end

  context 'not balanced bracket sequence' do
    context 'of lists' do
      it { expect { parse('[')    }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(']')    }.to raise_error(VimlValue::ParseError) }

      it { expect { parse('[[')   }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(']]')   }.to raise_error(VimlValue::ParseError) }
      it { expect { parse('][')   }.to raise_error(VimlValue::ParseError) }

      it { expect { parse('[[]')  }.to raise_error(VimlValue::ParseError) }
      it { expect { parse('[]]')  }.to raise_error(VimlValue::ParseError) }

      it { expect { parse('[]][') }.to raise_error(VimlValue::ParseError) }
      it { expect { parse('][[]') }.to raise_error(VimlValue::ParseError) }
    end

    context 'of dicts' do
      it { expect { parse('{')  }.to raise_error(VimlValue::ParseError) }
      it { expect { parse('}')  }.to raise_error(VimlValue::ParseError) }

      it { expect { parse('{{') }.to raise_error(VimlValue::ParseError) }
      it { expect { parse('}}') }.to raise_error(VimlValue::ParseError) }
      it { expect { parse('}{') }.to raise_error(VimlValue::ParseError) }
    end

    context 'of strings' do
      it { expect { parse(%q|'|)   }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(%q|"|)   }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(%q|'''|) }.to raise_error(VimlValue::ParseError) }
      it { expect { parse(%q|"""|) }.to raise_error(VimlValue::ParseError) }
    end

    context 'mixed [] and {}' do
      context 'inside list' do
        it { expect { parse('[{]')   }.to raise_error(VimlValue::ParseError) }
        it { expect { parse('[}]')   }.to raise_error(VimlValue::ParseError) }
      end

      context 'inside dict' do
        it { expect { parse("{'key': [}") }.to raise_error(VimlValue::ParseError) }
        it { expect { parse("{'key': ]}") }.to raise_error(VimlValue::ParseError) }
      end
    end
  end
end
