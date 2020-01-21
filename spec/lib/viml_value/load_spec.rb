# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Style/LambdaCall
describe 'VimlValue#load' do
  include Helpers::VimlValue
  include VimlValue::SerializationHelpers
  ParseError = VimlValue::ParseError
  DictRecursiveRef = VimlValue::Types::DictRecursiveRef
  ListRecursiveRef = VimlValue::Types::ListRecursiveRef

  let(:allow_toplevel_literals) { true }
  subject(:loading) do
    lambda do |value|
      VimlValue.load(value, allow_toplevel_literals: allow_toplevel_literals)
    end
  end

  # NOTE It is crucial for readability to keep indentations for visual
  # comprasion, so
  #   expect(actual).to become(expected).after(method)     }
  #   expect(actual).to fail_with(exception).while(method) }
  # is used instead of
  #   expect(method.call(actual)).to    eq(expected)           }
  #   expect { method.call(actual) }.to raise_error(exception) }
  # Also it's impossible to obtain actual being processed within block, so it
  # allows having better output messages

  shared_examples 'literals wrapped inside parsing context' do |wrap_actual, wrap_expected|
    let(:actual)   { wrap_actual.to_proc }
    let(:expected) { wrap_expected.to_proc }

    context 'integer' do
      it { expect(actual.('0')).to  become(expected.(0)).after(loading)  }
      it { expect(actual.('1')).to  become(expected.(1)).after(loading)  }
      it { expect(actual.('-2')).to become(expected.(-2)).after(loading) }
    end

    context 'float' do
      # from vim :help floating-point-format
      it { expect(actual.('0.0')).to         become(expected.(0.0)).after(loading)         }
      it { expect(actual.('123.456')).to     become(expected.(123.456)).after(loading)     }
      it { expect(actual.('+0.0001')).to     become(expected.(0.0001)).after(loading)      }
      it { expect(actual.('55.0')).to        become(expected.(55.0)).after(loading)        }
      it { expect(actual.('-0.123')).to      become(expected.(-0.123)).after(loading)      }
      it { expect(actual.('1.234e03')).to    become(expected.(1.234e03)).after(loading)    }
      it { expect(actual.('1.0E-6')).to      become(expected.(1.0E-6)).after(loading)      }
      it { expect(actual.('-3.1416e+88')).to become(expected.(-3.1416e+88)).after(loading) }
    end

    context 'function references' do
      it { expect(actual.("function('tr')")).to  become(expected.(funcref('tr'))).after(loading) }
      it { expect(actual.("function ('tr')")).to become(expected.(funcref('tr'))).after(loading) }
      it { expect(actual.('function("tr")')).to  become(expected.(funcref('tr'))).after(loading) }

      it { expect(actual.('function')).to      fail_with(ParseError).while(loading) }
      it { expect(actual.('function()')).to    fail_with(ParseError).while(loading) }
      it { expect(actual.('function(1)')).to   fail_with(ParseError).while(loading) }
      it { expect(actual.('function({})')).to  fail_with(ParseError).while(loading) }
      it { expect(actual.('function([])')).to  fail_with(ParseError).while(loading) }
      it { expect(actual.('function("tr"')).to fail_with(ParseError).while(loading) }
      it { expect(actual.('function"tr")')).to fail_with(ParseError).while(loading) }
      it { expect(actual.('function "tr"')).to fail_with(ParseError).while(loading) }
    end

    context 'boolean' do
      it { expect(actual.('v:true')).to become(expected.(true)).after(loading)   }
      it { expect(actual.('v:false')).to become(expected.(false)).after(loading) }
    end

    context 'v:null' do
      it { expect(actual.('v:null')).to become(expected.(nil)).after(loading) }
    end

    context 'recursive references' do
      it { expect(actual.('{...}')).to become(expected.(be_a(DictRecursiveRef))).after(loading) }
      it { expect(actual.('[...]')).to become(expected.(be_a(ListRecursiveRef))).after(loading) }
    end

    context 'string' do
      it { expect(actual.("'1'")).to become(expected.('1')).after(loading) }
      it { expect(actual.('"1"')).to become(expected.('1')).after(loading) }
      it { expect('""').to           become('').after(loading)             }
      it { expect("''").to           become('').after(loading)             }
      it { expect("'").to            fail_with(ParseError).while(loading)  }
      it { expect('"').to            fail_with(ParseError).while(loading)  }

      context 'escaping' do
        context 'of surrounding quotes' do
          context 'with backslash' do
            context 'single-quoted' do
              it { expect(actual.(%q|'\\''|)).to  fail_with(ParseError).while(loading) }
              it { expect(actual.(%q|'\\"'|)).to  become(expected.('\\"')).after(loading) }
              it { expect(actual.(%q|'\\'|)).to   become(expected.('\\')).after(loading)   }
              it { expect(actual.(%q|'\\\\'|)).to become(expected.('\\\\')).after(loading) }
            end

            context 'double-quoted' do
              it { expect(actual.(%q|"\\'"|)).to  become(expected.("'")).after(loading) }
              it { expect(actual.(%q|"\\""|)).to  become(expected.('"')).after(loading) }
              it { expect(actual.(%q|"\\"|)).to   fail_with(ParseError).while(loading)   }
              it { expect(actual.(%q|"\\\\"|)).to become(expected.('\\')).after(loading) }
            end
          end

          context 'with duplication' do
            context 'single-quoted' do
              it { expect(actual.("''''")).to   become(expected.("'")).after(loading)  }
              it { expect(actual.("''''''")).to become(expected.("''")).after(loading) }
            end

            context 'double-quoted' do
              it { expect(actual.('""""')).to   fail_with(ParseError).while(loading) }
              it { expect(actual.('""""""')).to fail_with(ParseError).while(loading) }
            end

            context 'mixing duplication and backslash' do
              # Have to be tested within integration tests as some quotes escaping
              # is valid in terms of tokenization, but invalid in terms of racc parsing
              # A bit verbose, but it helps to understand how tricky escaping works
              # in vim and to ensure that everything works properly
              it { expect(actual.('\\"""""')).to fail_with(ParseError).while(loading)    }
              it { expect(actual.('"\\""""')).to fail_with(ParseError).while(loading)    }
              it { expect(actual.('""\\"""')).to fail_with(ParseError).while(loading)    }
              it { expect(actual.('"""\\""')).to fail_with(ParseError).while(loading)    }
              it { expect(actual.('""""\\"')).to fail_with(ParseError).while(loading)    }
              it { expect(actual.("\\'''''")).to fail_with(ParseError).while(loading)    }
              it { expect(actual.("'\\''''")).to fail_with(ParseError).while(loading)    }
              it { expect(actual.("''\\'''")).to fail_with(ParseError).while(loading)    }
              it { expect(actual.("'''\\''")).to fail_with(ParseError).while(loading)    }
              it { expect(actual.("''''\\'")).to fail_with(ParseError).while(loading)    }

              it { expect(actual.('\\""""')).to  fail_with(ParseError).while(loading)    }
              it { expect(actual.('"\\"""')).to  fail_with(ParseError).while(loading)    }
              it { expect(actual.('""\\""')).to  fail_with(ParseError).while(loading)    }
              it { expect(actual.('"""\\"')).to  fail_with(ParseError).while(loading)    }
              it { expect(actual.('""""\\')).to  fail_with(ParseError).while(loading)    }
              it { expect(actual.("\\''''")).to  fail_with(ParseError).while(loading)    }
              it { expect(actual.("'\\'''")).to  become(expected.("\\'")).after(loading) }
              it { expect(actual.("''\\''")).to  fail_with(ParseError).while(loading)    }
              it { expect(actual.("'''\\'")).to  become(expected.("'\\")).after(loading) }
              it { expect(actual.("''''\\")).to  fail_with(ParseError).while(loading)    }

              it { expect(actual.('\\"""')).to   fail_with(ParseError).while(loading)    }
              it { expect(actual.('"\\""')).to   become(expected.('"')).after(loading)   }
              it { expect(actual.('""\\"')).to   fail_with(ParseError).while(loading)    }
              it { expect(actual.('"""\\')).to   fail_with(ParseError).while(loading)    }
              it { expect(actual.("\\'''")).to   fail_with(ParseError).while(loading)    }
              it { expect(actual.("'\\''")).to   fail_with(ParseError).while(loading)    }
              it { expect(actual.("''\\'")).to   fail_with(ParseError).while(loading)    }
              it { expect(actual.("'''\\")).to   fail_with(ParseError).while(loading)    }

              it { expect(actual.('\\""')).to   fail_with(ParseError).while(loading)     }
              it { expect(actual.('"\\"')).to   fail_with(ParseError).while(loading)     }
              it { expect(actual.('""\\')).to   fail_with(ParseError).while(loading)     }
              it { expect(actual.("\\''")).to   fail_with(ParseError).while(loading)     }
              it { expect(actual.("'\\'")).to   become(expected.('\\')).after(loading)   }
              it { expect(actual.("''\\")).to   fail_with(ParseError).while(loading)     }
            end
          end
        end
      end
    end
  end

  shared_examples 'collections wrapped inside parsing context' do |wrap_actual, wrap_expected|
    let(:actual)   { wrap_actual.to_proc }
    let(:expected) { wrap_expected.to_proc }

    context 'list' do
      it { expect('[]').to  become([]).after(loading)  }
      it { expect('[1]').to become([1]).after(loading) }
    end

    context 'dict' do
      it { expect('{}').to become({}).after(loading) }
      it { expect('{"key": 2}').to become('key'=> 2).after(loading) }
    end

    context 'invalid' do
      it { expect(']').to fail_with(ParseError).while(loading) }
      it { expect('}').to fail_with(ParseError).while(loading) }
      it { expect('[').to fail_with(ParseError).while(loading) }
      it { expect('{').to fail_with(ParseError).while(loading) }
    end
  end

  shared_examples 'values wrapped inside parsing context' do |wrap_actual, wrap_expected|
    include_examples 'literals wrapped inside parsing context', wrap_actual, wrap_expected
    include_examples 'collections wrapped inside parsing context', wrap_actual, wrap_expected
  end

  context 'inside list' do
    include_examples 'values wrapped inside parsing context',
      ->(given_str)    { "[#{given_str}]" },
      ->(expected_obj) { [expected_obj] }
  end

  context 'inside dict' do
    include_examples 'values wrapped inside parsing context',
      ->(given_str)    { "{'key': #{given_str}}" },
      ->(expected_obj) { {'key' => expected_obj} }
  end

  context 'inside deeply nested structure' do
    include_examples 'values wrapped inside parsing context',
      ->(given_str)    { %(  [1,[ { 'key' : #{given_str}, } , 2,  [ "3"  ]], 4,]) },
      ->(expected_obj) { [1, [{'key' => expected_obj}, 2, ['3']], 4] }
  end

  context 'toplevel' do
    it { expect('').to         become(nil).after(loading)           }
    it { expect('1,2').to      fail_with(ParseError).while(loading) }
    it { expect('"key": 1').to fail_with(ParseError).while(loading) }

    context 'when allow_toplevel_literals == true' do
      let(:allow_toplevel_literals) { true }

      include_examples 'values wrapped inside parsing context',
        ->(given_str)    { given_str },
        ->(expected_obj) { expected_obj }
    end

    context 'when allow_toplevel_literals == false' do
      let(:allow_toplevel_literals) { false }

      context 'collections' do
        include_examples 'collections wrapped inside parsing context',
          ->(given_str)    { given_str },
          ->(expected_obj) { expected_obj }
      end

      context 'literals' do
        it { expect('1').to              fail_with(ParseError).while(loading) }
        it { expect('1.2').to            fail_with(ParseError).while(loading) }
        it { expect('"str1"').to         fail_with(ParseError).while(loading) }
        it { expect("'str2'").to         fail_with(ParseError).while(loading) }
        it { expect('v:null').to         fail_with(ParseError).while(loading) }
        it { expect('v:true').to         fail_with(ParseError).while(loading) }
        it { expect('v:false').to        fail_with(ParseError).while(loading) }
        it { expect('[...]').to          fail_with(ParseError).while(loading) }
        it { expect('{...}').to          fail_with(ParseError).while(loading) }
        it { expect('function("tr")').to fail_with(ParseError).while(loading) }
      end
    end
  end
end
# rubocop:enable Style/LambdaCall
