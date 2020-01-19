# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Parser do
  def function(name)
    VimlValue::Visitors::ToRuby::Funcref.new(name)
  end

  def self.function(name)
    VimlValue::Visitors::ToRuby::Funcref.new(name)
  end

  def dict_recursive_ref
    VimlValue::Visitors::ToRuby::DictRecursiveReference
  end

  def list_recursive_ref
    VimlValue::Visitors::ToRuby::ListRecursiveReference
  end

  matcher :raise_on_parsing do |exception|
    supports_block_expectations
    match do |actual|
      @parsed = VimlValue.load(actual)
      false
    rescue exception
      true
    end

    description do |actual|
      "raise #{VimlValue::ParseError} while parsing #{actual.inspect}"
    end

    failure_message do |actual|
      ["expected #{described_class}",
       "to raise #{exception}",
       "while parsing #{actual.inspect},",
       "got #{@parsed.inspect}"].join(' ')
    end
  end

  matcher :be_parsed_as do |expected|
    match do |actual|
      @parsed = VimlValue.load(actual)
      eq(expected).matches?(@parsed)
    end

    description do |actual|
      "parse #{actual.inspect} as #{expected.inspect}"
    end

    failure_message do |actual|
      ["expected #{described_class}",
       "to parse #{actual.inspect}",
       "as #{expected.inspect},",
       "got #{@parsed.inspect}"].join(' ')
    end
  end

  shared_examples 'wrapped value' do |wrap, wrap_result|
    shared_examples 'it can parse vim internal (starts with v:) variable' do |name, ruby_value|
      it { expect(wrap.call("v:#{name}")).to be_parsed_as(wrap_result.call(ruby_value)) }

      it { expect(wrap.call("a:#{name}")).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call("l:#{name}")).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call("w:#{name}")).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call("b:#{name}")).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call("g:#{name}")).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call("s:#{name}")).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(":#{name}")).to  raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(name.to_s)).to   raise_on_parsing(VimlValue::ParseError) }
    end

    context 'integer' do
      it { expect(wrap.call('1')).to   be_parsed_as(wrap_result.call(1))    }
      it { expect(wrap.call('0')).to   be_parsed_as(wrap_result.call(0))    }

      context 'with +|- sign' do
        it { expect(wrap.call('+1')).to  be_parsed_as(wrap_result.call(1))  }
        it { expect(wrap.call('+0')).to  be_parsed_as(wrap_result.call(0))  }
        it { expect(wrap.call('-1')).to  be_parsed_as(wrap_result.call(-1)) }
        it { expect(wrap.call('-0')).to  be_parsed_as(wrap_result.call(0))  }
      end

      context 'leading zeros' do
        it { expect(wrap.call('01')).to  be_parsed_as(wrap_result.call(1))  }
        it { expect(wrap.call('-01')).to be_parsed_as(wrap_result.call(-1)) }
      end
    end

    context 'float' do
      # vim :help floating-point-format
      it { expect(wrap.call('1.0')).to  be_parsed_as(wrap_result.call(1.0))      }
      it { expect(wrap.call('1.2')).to  be_parsed_as(wrap_result.call(1.2))      }
      it { expect(wrap.call('0.2')).to  be_parsed_as(wrap_result.call(0.2))      }
      it { expect(wrap.call('1.')).to    raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call('.1')).to    raise_on_parsing(VimlValue::ParseError) }

      context 'leading zeros' do
        it { expect(wrap.call('01.0')).to  be_parsed_as(wrap_result.call(1.0))   }
        it { expect(wrap.call('-01.0')).to be_parsed_as(wrap_result.call(-1.0))  }
      end

      context 'with +|- sign' do
        it { expect(wrap.call('+1.2')).to be_parsed_as(wrap_result.call(1.2))    }
        it { expect(wrap.call('+1.0')).to be_parsed_as(wrap_result.call(1.0))    }
        it { expect(wrap.call('+0.2')).to be_parsed_as(wrap_result.call(0.2))    }

        it { expect(wrap.call('-1.0')).to be_parsed_as(wrap_result.call(-1.0))   }
        it { expect(wrap.call('-1.2')).to be_parsed_as(wrap_result.call(-1.2))   }
        it { expect(wrap.call('-0.2')).to be_parsed_as(wrap_result.call(-0.2))   }
      end

      context 'exponential form' do
        it { expect(wrap.call('1.2e34')).to   be_parsed_as(wrap_result.call(1.2e34))  }
        it { expect(wrap.call('1.2e034')).to  be_parsed_as(wrap_result.call(1.2e34))  }
        it { expect(wrap.call('1.2e+34')).to  be_parsed_as(wrap_result.call(1.2e34))  }
        it { expect(wrap.call('1.2e+034')).to be_parsed_as(wrap_result.call(1.2e34))  }
        it { expect(wrap.call('1.2e-34')).to  be_parsed_as(wrap_result.call(1.2e-34)) }
        it { expect(wrap.call('1.2e-34')).to  be_parsed_as(wrap_result.call(1.2e-34)) }

        it { expect(wrap.call('1.2E34')).to   be_parsed_as(wrap_result.call(1.2e34))  }
        it { expect(wrap.call('1.2E034')).to  be_parsed_as(wrap_result.call(1.2e34))  }
        it { expect(wrap.call('1.2E+34')).to  be_parsed_as(wrap_result.call(1.2e34))  }
        it { expect(wrap.call('1.2E+034')).to be_parsed_as(wrap_result.call(1.2e34))  }
        it { expect(wrap.call('1.2E-34')).to  be_parsed_as(wrap_result.call(1.2e-34)) }
        it { expect(wrap.call('1.2E-34')).to  be_parsed_as(wrap_result.call(1.2e-34)) }
      end
    end

    context 'function references' do
      it { expect(wrap.call(%q|function('tr')|)).to  be_parsed_as(wrap_result.call(function('tr'))) }
      it { expect(wrap.call(%q|function ('tr')|)).to be_parsed_as(wrap_result.call(function('tr'))) }
      it { expect(wrap.call(%q|function("tr")|)).to  be_parsed_as(wrap_result.call(function('tr'))) }

      it { expect(wrap.call(%q|function|)).to      raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|function()|)).to    raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|function(1)|)).to   raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|function({})|)).to  raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|function([])|)).to  raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|function("tr"|)).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|function"tr")|)).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|function "tr"|)).to raise_on_parsing(VimlValue::ParseError) }
    end

    context 'boolean' do
      it_behaves_like 'it can parse vim internal (starts with v:) variable', 'true',  true
      it_behaves_like 'it can parse vim internal (starts with v:) variable', 'false', false
    end

    context 'v:null' do
      it_behaves_like 'it can parse vim internal (starts with v:) variable', 'null', nil
    end

    context 'recursive references' do
      it { expect(wrap.call(%q|{...}|)).to be_parsed_as(wrap_result.call(dict_recursive_ref)) }
      it { expect(wrap.call(%q|[...]|)).to be_parsed_as(wrap_result.call(list_recursive_ref)) }

      it { expect(wrap.call(%q|[....]|)).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|{....}|)).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|[..]|)).to   raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|{..}|)).to   raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|[.]|)).to    raise_on_parsing(VimlValue::ParseError) }
      it { expect(wrap.call(%q|{.}|)).to    raise_on_parsing(VimlValue::ParseError) }
    end

    context 'string' do
      it { expect(wrap.call("'1'")).to be_parsed_as(wrap_result.call('1')) }
      it { expect(wrap.call('"1"')).to be_parsed_as(wrap_result.call('1')) }

      context 'escaping' do
        context 'of surrounding quotes' do
          context 'with backslash' do
            context 'single quote' do
              it { expect(wrap.call("'\\''")).to  raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("'\\'")).to   be_parsed_as(wrap_result.call('\\'))    }
              it { expect(wrap.call("'\\\\'")).to be_parsed_as(wrap_result.call('\\\\'))  }
            end

            context 'double quote' do
              it { expect(wrap.call('"\\""')).to  be_parsed_as(wrap_result.call('"'))     }
              it { expect(wrap.call('"\\"')).to   raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('"\\\\"')).to be_parsed_as(wrap_result.call('\\'))    }
            end
          end

          context 'with duplication' do
            context 'single-quoted' do
              it { expect(wrap.call("''''")).to   be_parsed_as(wrap_result.call("'"))  }
              it { expect(wrap.call("''''''")).to be_parsed_as(wrap_result.call("''")) }
            end

            context 'double-quoted' do
              it { expect(wrap.call('""""')).to   raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('""""""')).to raise_on_parsing(VimlValue::ParseError) }
            end

            context 'mixing single and double-quoted' do
              # have to be tested in terms of integration as some quotes escaping
              # is valid in terms of tokenization, but invalid as a viml value
              it { expect(wrap.call(%q|"''"|)).to be_parsed_as(wrap_result.call("''")) }
              it { expect(wrap.call(%q|'""'|)).to be_parsed_as(wrap_result.call('""')) }

              # A bit verbose, but helps to understand how tricky escaping works
              # in vim and ensure that everything works properly
              it { expect(wrap.call('\\"""""')).to raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('"\\""""')).to raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('""\\"""')).to raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('"""\\""')).to raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('""""\\"')).to raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("\\'''''")).to raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("'\\''''")).to raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("''\\'''")).to raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("'''\\''")).to raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("''''\\'")).to raise_on_parsing(VimlValue::ParseError) }

              it { expect(wrap.call('\\""""')).to  raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('"\\"""')).to  raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('""\\""')).to  raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('"""\\"')).to  raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('""""\\')).to  raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("\\''''")).to  raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("'\\'''")).to  be_parsed_as(wrap_result.call("\\'"))   }
              it { expect(wrap.call("''\\''")).to  raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("'''\\'")).to  be_parsed_as(wrap_result.call("'\\"))   }
              it { expect(wrap.call("''''\\")).to  raise_on_parsing(VimlValue::ParseError) }

              it { expect(wrap.call('\\"""')).to   raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('"\\""')).to   be_parsed_as(wrap_result.call('"'))     }
              it { expect(wrap.call('""\\"')).to   raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call('"""\\')).to   raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("\\'''")).to   raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("'\\''")).to   raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("''\\'")).to   raise_on_parsing(VimlValue::ParseError) }
              it { expect(wrap.call("'''\\")).to   raise_on_parsing(VimlValue::ParseError) }

              it { expect(wrap.call(%q|"\\'"|)).to be_parsed_as(wrap_result.call("'"))     }
              it { expect(wrap.call("'\\'''")).to  be_parsed_as(wrap_result.call("\\'"))   }
              it { expect(wrap.call("'''\\'")).to  be_parsed_as(wrap_result.call("'\\"))   }
            end
          end
        end
      end
    end
  end

  context 'toplevel' do
    include_examples 'wrapped value',
      ->(given_str)    { given_str },
      ->(expected_obj) { expected_obj }
  end

  context 'inside list' do
    include_examples 'wrapped value',
      ->(given_str)    { "[#{given_str}]" },
      ->(expected_obj) { [expected_obj] }

    it { expect('1,2').to raise_on_parsing(VimlValue::ParseError) }

    context 'trailing comma' do
      it { expect('[1,]').to  be_parsed_as([1])                       }
      it { expect('[1,,]').to raise_on_parsing(VimlValue::ParseError) }
      it { expect('[,]').to   raise_on_parsing(VimlValue::ParseError) }
    end
  end

  context 'inside dict' do
    include_examples 'wrapped value',
      ->(given_str)    { "{'key': #{given_str}}" },
      ->(expected_obj) { {'key' => expected_obj} }

    context 'trailing comma' do
      it { expect('{"key": 1,}').to  be_parsed_as('key' => 1) }
      it { expect('{"key": 1,,]').to raise_on_parsing(VimlValue::ParseError) }
      it { expect('{"key":,}').to    raise_on_parsing(VimlValue::ParseError) }
      it { expect('{,}').to          raise_on_parsing(VimlValue::ParseError) }
    end

    context 'incorrect pairs' do
      it { expect(%q|{1}|).to      raise_on_parsing(VimlValue::ParseError) }
      it { expect(%q|{1: 1}|).to   raise_on_parsing(VimlValue::ParseError) }
      it { expect(%q|{1: '1'}|).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(%q|{''}|).to     raise_on_parsing(VimlValue::ParseError) }
      it { expect(%q|{""}|).to     raise_on_parsing(VimlValue::ParseError) }
    end
  end

  context 'inside deeply nested structure' do
    include_examples 'wrapped value',
      ->(given_str)    { %|[1,[ { 'key' : #{given_str} } , 2, function('Fn'), ["3"]], 4]| },
      ->(expected_obj) { [1, [{'key' => expected_obj}, 2, function('Fn'), ['3']], 4] }
  end

  context 'not balanced bracket sequence' do
    context 'of lists' do
      it { expect('[').to raise_on_parsing(VimlValue::ParseError) }
      it { expect(']').to raise_on_parsing(VimlValue::ParseError) }

      it { expect('[[').to raise_on_parsing(VimlValue::ParseError) }
      it { expect(']]').to raise_on_parsing(VimlValue::ParseError) }
      it { expect('][').to raise_on_parsing(VimlValue::ParseError) }

      it { expect('[[]').to raise_on_parsing(VimlValue::ParseError) }
      it { expect('[]]').to raise_on_parsing(VimlValue::ParseError) }

      it { expect('[]][').to raise_on_parsing(VimlValue::ParseError) }
      it { expect('][[]').to raise_on_parsing(VimlValue::ParseError) }
    end

    context 'of dicts' do
      it { expect('{').to raise_on_parsing(VimlValue::ParseError) }
      it { expect('}').to raise_on_parsing(VimlValue::ParseError) }

      it { expect('{{').to raise_on_parsing(VimlValue::ParseError) }
      it { expect('}}').to raise_on_parsing(VimlValue::ParseError) }
      it { expect('}{').to raise_on_parsing(VimlValue::ParseError) }
    end

    context 'of strings' do
      it { expect(%q|'|).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(%q|"|).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(%q|'''|).to raise_on_parsing(VimlValue::ParseError) }
      it { expect(%q|"""|).to raise_on_parsing(VimlValue::ParseError) }
    end

    context 'mixed [] and {}' do
      context 'inside list' do
        it { expect('[{]').to raise_on_parsing(VimlValue::ParseError) }
        it { expect('[}]').to raise_on_parsing(VimlValue::ParseError) }
      end

      context 'inside dict' do
        it { expect("{'key': [}").to raise_on_parsing(VimlValue::ParseError) }
        it { expect("{'key': ]}").to raise_on_parsing(VimlValue::ParseError) }
      end
    end
  end
end
