# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Style/LambdaCall
describe VimlValue do
  include Helpers::VimlValue
  include VimlValue::SerializationHelpers
  extend VimlValue::SerializationHelpers

  ParseError       ||= VimlValue::ParseError
  DictRecursiveRef ||= VimlValue::Types::DictRecursiveRef
  ListRecursiveRef ||= VimlValue::Types::ListRecursiveRef
  None             ||= VimlValue::Types::None

  describe '#load' do
    let(:allow_toplevel_literals) { true }
    let(:options) { {allow_toplevel_literals: allow_toplevel_literals} }
    subject do
      ->(string) { VimlValue.load(string, **options) }
    end

    def be_loaded_as(expected)
      Helpers::VimlValue::BeLoadedAs.new(expected, &subject)
    end

    def fail_loading_with(exception)
      Helpers::VimlValue::FailLoadingWith.new(exception, &subject)
    end

    shared_examples 'literals wrapped inside a parsing context' do |wrap_actual, wrap_expected|
      let(:actual)   { wrap_actual.to_proc }
      let(:expected) { wrap_expected.to_proc }

      context 'integer' do
        it { expect(actual.('0')).to  be_loaded_as(expected.(0))  }
        it { expect(actual.('1')).to  be_loaded_as(expected.(1))  }
        it { expect(actual.('-2')).to be_loaded_as(expected.(-2)) }
      end

      context 'float' do
        # from vim :help floating-point-format
        it { expect(actual.('0.0')).to         be_loaded_as(expected.(0.0))         }
        it { expect(actual.('123.456')).to     be_loaded_as(expected.(123.456))     }
        it { expect(actual.('+0.0001')).to     be_loaded_as(expected.(0.0001))      }
        it { expect(actual.('55.0')).to        be_loaded_as(expected.(55.0))        }
        it { expect(actual.('-0.123')).to      be_loaded_as(expected.(-0.123))      }
        it { expect(actual.('1.234e03')).to    be_loaded_as(expected.(1.234e03))    }
        it { expect(actual.('1.0E-6')).to      be_loaded_as(expected.(1.0E-6))      }
        it { expect(actual.('-3.1416e+88')).to be_loaded_as(expected.(-3.1416e+88)) }
      end

      context 'function references' do
        it { expect(actual.("function('tr')")).to  be_loaded_as(expected.(funcref('tr'))) }
        it { expect(actual.('function("tr")')).to  be_loaded_as(expected.(funcref('tr'))) }
        it { expect(actual.("function ('tr')")).to be_loaded_as(expected.(funcref('tr'))) }

        it { expect(actual.('function')).to      fail_loading_with(ParseError) }
        it { expect(actual.('function()')).to    fail_loading_with(ParseError) }
        it { expect(actual.('function(1)')).to   fail_loading_with(ParseError) }
        it { expect(actual.('function({})')).to  fail_loading_with(ParseError) }
        it { expect(actual.('function([])')).to  fail_loading_with(ParseError) }
        it { expect(actual.('function("tr"')).to fail_loading_with(ParseError) }
        it { expect(actual.('function"tr")')).to fail_loading_with(ParseError) }
        it { expect(actual.('function "tr"')).to fail_loading_with(ParseError) }
        it { expect(actual.('function "tr"')).to fail_loading_with(ParseError) }
      end

      context 'boolean' do
        it { expect(actual.('v:true')).to be_loaded_as(expected.(true))   }
        it { expect(actual.('v:false')).to be_loaded_as(expected.(false)) }
      end

      context 'v:null' do
        it { expect(actual.('v:null')).to be_loaded_as(expected.(nil)) }
      end

      context 'v:none' do
        it { expect(actual.('v:none')).to be_loaded_as(expected.(none)) }
        it { expect(actual.('None')).to   be_loaded_as(expected.(none)) }
      end

      context 'recursive references' do
        it { expect(actual.('{...}')).to be_loaded_as(expected.(DictRecursiveRef.new)) }
        it { expect(actual.('[...]')).to be_loaded_as(expected.(ListRecursiveRef.new)) }
      end

      context 'string' do
        it { expect(actual.("'1'")).to be_loaded_as(expected.('1'))  }
        it { expect(actual.('"1"')).to be_loaded_as(expected.('1'))  }
        it { expect(actual.('""')).to  be_loaded_as(expected.(''))   }
        it { expect(actual.("''")).to  be_loaded_as(expected.(''))   }
        it { expect(actual.("'")).to   fail_loading_with(ParseError) }
        it { expect(actual.('"')).to   fail_loading_with(ParseError) }

        context 'escaping' do
          context 'of surrounding quotes' do
            context 'with backslash' do
              context 'single-quoted' do
                it { expect(actual.(%q|'\\''|)).to  fail_loading_with(ParseError)   }
                it { expect(actual.(%q|'\\"'|)).to  be_loaded_as(expected.('\\"'))  }
                it { expect(actual.(%q|'\\'|)).to   be_loaded_as(expected.('\\'))   }
                it { expect(actual.(%q|'\\\\'|)).to be_loaded_as(expected.('\\\\')) }
              end

              context 'double-quoted' do
                it { expect(actual.(%q|"\\'"|)).to  be_loaded_as(expected.("'"))  }
                it { expect(actual.(%q|"\\""|)).to  be_loaded_as(expected.('"'))  }
                it { expect(actual.(%q|"\\"|)).to   fail_loading_with(ParseError) }
                it { expect(actual.(%q|"\\\\"|)).to be_loaded_as(expected.('\\')) }
              end
            end

            context 'with duplication' do
              context 'single-quoted' do
                it { expect(actual.("''''")).to   be_loaded_as(expected.("'"))  }
                it { expect(actual.("''''''")).to be_loaded_as(expected.("''")) }
              end

              context 'double-quoted' do
                it { expect(actual.('""""')).to   fail_loading_with(ParseError) }
                it { expect(actual.('""""""')).to fail_loading_with(ParseError) }
              end

              context 'mixing duplication and backslash' do
                # Have to be tested within integration tests as some quotes
                # escaping are valid in terms of tokenization, but invalid in
                # terms of racc parsing A bit verbose, but it helps to
                # understand how tricky escaping works in vim and to ensure that
                # everything works properly
                it { expect(actual.('\\"""""')).to fail_loading_with(ParseError)  }
                it { expect(actual.('"\\""""')).to fail_loading_with(ParseError)  }
                it { expect(actual.('""\\"""')).to fail_loading_with(ParseError)  }
                it { expect(actual.('"""\\""')).to fail_loading_with(ParseError)  }
                it { expect(actual.('""""\\"')).to fail_loading_with(ParseError)  }
                it { expect(actual.("\\'''''")).to fail_loading_with(ParseError)  }
                it { expect(actual.("'\\''''")).to fail_loading_with(ParseError)  }
                it { expect(actual.("''\\'''")).to fail_loading_with(ParseError)  }
                it { expect(actual.("'''\\''")).to fail_loading_with(ParseError)  }
                it { expect(actual.("''''\\'")).to fail_loading_with(ParseError)  }

                it { expect(actual.('\\""""')).to  fail_loading_with(ParseError)  }
                it { expect(actual.('"\\"""')).to  fail_loading_with(ParseError)  }
                it { expect(actual.('""\\""')).to  fail_loading_with(ParseError)  }
                it { expect(actual.('"""\\"')).to  fail_loading_with(ParseError)  }
                it { expect(actual.('""""\\')).to  fail_loading_with(ParseError)  }
                it { expect(actual.("\\''''")).to  fail_loading_with(ParseError)  }
                it { expect(actual.("'\\'''")).to  be_loaded_as(expected.("\\'")) }
                it { expect(actual.("''\\''")).to  fail_loading_with(ParseError)  }
                it { expect(actual.("'''\\'")).to  be_loaded_as(expected.("'\\")) }
                it { expect(actual.("''''\\")).to  fail_loading_with(ParseError)  }

                it { expect(actual.('\\"""')).to   fail_loading_with(ParseError)  }
                it { expect(actual.('"\\""')).to   be_loaded_as(expected.('"'))   }
                it { expect(actual.('""\\"')).to   fail_loading_with(ParseError)  }
                it { expect(actual.('"""\\')).to   fail_loading_with(ParseError)  }
                it { expect(actual.("\\'''")).to   fail_loading_with(ParseError)  }
                it { expect(actual.("'\\''")).to   fail_loading_with(ParseError)  }
                it { expect(actual.("''\\'")).to   fail_loading_with(ParseError)  }
                it { expect(actual.("'''\\")).to   fail_loading_with(ParseError)  }

                it { expect(actual.('\\""')).to    fail_loading_with(ParseError)  }
                it { expect(actual.('"\\"')).to    fail_loading_with(ParseError)  }
                it { expect(actual.('""\\')).to    fail_loading_with(ParseError)  }
                it { expect(actual.("\\''")).to    fail_loading_with(ParseError)  }
                it { expect(actual.("'\\'")).to    be_loaded_as(expected.('\\'))  }
                it { expect(actual.("''\\")).to    fail_loading_with(ParseError)  }
              end
            end
          end
        end
      end
    end

    shared_examples 'collections wrapped inside a parsing context' do |wrap_actual, wrap_expected|
      let(:actual)   { wrap_actual.to_proc }
      let(:expected) { wrap_expected.to_proc }

      context 'list' do
        it { expect(actual.('[]')).to  be_loaded_as(expected.([])) }
        it { expect(actual.('[1]')).to be_loaded_as(expected.([1])) }
      end

      context 'dict' do
        it { expect(actual.('{}')).to be_loaded_as(expected.({})) }
        it { expect(actual.('{"key": 2}')).to be_loaded_as(expected.('key'=> 2)) }
      end

      context 'invalid' do
        it { expect(actual.(']')).to fail_loading_with(ParseError) }
        it { expect(actual.('}')).to fail_loading_with(ParseError) }
        it { expect(actual.('[')).to fail_loading_with(ParseError) }
        it { expect(actual.('{')).to fail_loading_with(ParseError) }
      end
    end

    shared_examples 'values wrapped inside a parsing context' do |wrap_actual, wrap_expected|
      include_examples 'literals wrapped inside a parsing context',
        wrap_actual,
        wrap_expected
      include_examples 'collections wrapped inside a parsing context',
        wrap_actual,
        wrap_expected
    end

    context 'inside list' do
      include_examples 'values wrapped inside a parsing context',
        ->(given_str)    { "[#{given_str}]" },
        ->(expected_obj) { [expected_obj]   }
    end

    context 'inside dict' do
      include_examples 'values wrapped inside a parsing context',
        ->(given_str)    { "{'key': #{given_str}}" },
        ->(expected_obj) { {'key' => expected_obj} }
    end

    context 'inside funcref curried arguments list' do
      include_examples 'values wrapped inside a parsing context',
        ->(given_str)    { "function('Fn', #{given_str})" },
        ->(expected_obj) { funcref('Fn', expected_obj) }
    end

    context 'inside deeply nested structure' do
      include_examples 'values wrapped inside a parsing context',
        ->(given_str)    { %(  [1,[ { 'key' : #{given_str}, } , 2,  [ "3"  ]], 4,]) },
        ->(expected_obj) { [1, [{'key' => expected_obj}, 2, ['3']], 4]              }
    end

    context 'toplevel' do
      it { expect('').to         be_loaded_as(nil) }
      it { expect('1,2').to      fail_loading_with(ParseError) }
      it { expect('"key": 1').to fail_loading_with(ParseError) }
      it { expect("'key': 1").to fail_loading_with(ParseError) }

      context 'when allow_toplevel_literals == true' do
        let(:allow_toplevel_literals) { true }

        include_examples 'values wrapped inside a parsing context',
          ->(given_str)    { given_str    },
          ->(expected_obj) { expected_obj }
      end

      context 'when allow_toplevel_literals == false' do
        let(:allow_toplevel_literals) { false }

        context 'collections' do
          include_examples 'collections wrapped inside a parsing context',
            ->(given_str)    { given_str    },
            ->(expected_obj) { expected_obj }
        end

        context 'literals' do
          it { expect('1').to              fail_loading_with(ParseError) }
          it { expect('1.2').to            fail_loading_with(ParseError) }
          it { expect('"str1"').to         fail_loading_with(ParseError) }
          it { expect("'str2'").to         fail_loading_with(ParseError) }
          it { expect('v:null').to         fail_loading_with(ParseError) }
          it { expect('v:none').to         fail_loading_with(ParseError) }
          it { expect('None').to           fail_loading_with(ParseError) }
          it { expect('v:true').to         fail_loading_with(ParseError) }
          it { expect('v:false').to        fail_loading_with(ParseError) }
          it { expect('[...]').to          fail_loading_with(ParseError) }
          it { expect('{...}').to          fail_loading_with(ParseError) }
          it { expect('function("tr")').to fail_loading_with(ParseError) }
          it { expect("function('tr')").to fail_loading_with(ParseError) }
        end
      end
    end
  end
end
# rubocop:enable Style/LambdaCall
