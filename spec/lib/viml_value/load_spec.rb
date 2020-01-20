# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Style/LambdaCall
describe 'VimlValue#load' do
  include VimlValue::SerializationHelpers
  include Helpers::VimlValue
  ParseError = VimlValue::ParseError

  subject(:loading) do
    ->(value) { VimlValue.load(value, allow_toplevel_literals: true) }
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

  shared_examples 'values inside parsing context' do |wrap_actual:, wrap_expected:|
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
      it { expect(actual.('{...}')).to become(expected.(dict_recursive_ref)).after(loading) }
      it { expect(actual.('[...]')).to become(expected.(list_recursive_ref)).after(loading) }
    end

    context 'string' do
      it { expect(actual.("'1'")).to become(expected.('1')).after(loading) }
      it { expect(actual.('"1"')).to become(expected.('1')).after(loading) }

      # some of them are tokenized correctly, but cause parse errors, so it
      # should be tested on parser level
      context 'escaping' do
        context 'of surrounding quotes' do
          context 'with backslash' do
            context 'single quote' do
              it { expect(actual.("'\\''")).to  fail_with(ParseError).while(loading)     }
              it { expect(actual.("'\\'")).to   become(expected.('\\')).after(loading)   }
              it { expect(actual.("'\\\\'")).to become(expected.('\\\\')).after(loading) }
            end

            context 'double quote' do
              it { expect(actual.('"\\""')).to  become(expected.('"')).after(loading)  }
              it { expect(actual.('"\\"')).to   fail_with(ParseError).while(loading)   }
              it { expect(actual.('"\\\\"')).to become(expected.('\\')).after(loading) }
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

            let(:parse_exception) {  }
            context 'mixing single and double-quoted' do
              # Have to be tested in terms of integration as some quotes escaping
              # is valid in terms of tokenization, but invalid as a viml value
              # A bit verbose, but it helps to understand how tricky escaping works
              # in vim and to ensure that everything works properly
              it { expect(actual.('\\"""""')).to fail_with(ParseError).while(loading)   }
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

              it { expect(actual.(%q|"\\'"|)).to become(expected.("'")).after(loading)   }
              it { expect(actual.("'\\'''")).to  become(expected.("\\'")).after(loading) }
              it { expect(actual.("'''\\'")).to  become(expected.("'\\")).after(loading) }
            end
          end
        end
      end
    end
  end

  context 'toplevel' do
    include_examples 'values inside parsing context',
      wrap_actual:   ->(given_str)    { given_str },
      wrap_expected: ->(expected_obj) { expected_obj }

    context 'nothing' do
      it { expect('').to become(nil).after(loading) }
    end
  end

  context 'inside list' do
    include_examples 'values inside parsing context',
      wrap_actual:   ->(given_str)    { "[#{given_str}]" },
      wrap_expected: ->(expected_obj) { [expected_obj] }

    it { expect('[]').to become([]).after(loading)             }
    it { expect('1,2').to fail_with(ParseError).while(loading) }

    context 'trailing comma' do
      it { expect('[1,]').to  become([1]).after(loading)           }
      it { expect('[1,,]').to fail_with(ParseError).while(loading) }
      it { expect('[,]').to   fail_with(ParseError).while(loading) }
    end
  end

  context 'inside dict' do
    include_examples 'values inside parsing context',
      wrap_actual:   ->(given_str)    { "{'key': #{given_str}}" },
      wrap_expected: ->(expected_obj) { {'key' => expected_obj} }

    it { expect('{}').to become({}).after(loading) }
    it { expect('"key": 1').to fail_with(ParseError).while(loading) }

    context 'trailing comma' do
      it { expect('{"key": 1,}').to  become('key' => 1).after(loading)    }
      it { expect('{"key": 1,,]').to fail_with(ParseError).while(loading) }
      it { expect('{"key":,}').to    fail_with(ParseError).while(loading) }
      it { expect('{,}').to          fail_with(ParseError).while(loading) }
    end

    context 'incorrect pairs' do
      it { expect('{1}').to      fail_with(ParseError).while(loading) }
      it { expect('{1: 1}').to   fail_with(ParseError).while(loading) }
      it { expect("{1: '1'}").to fail_with(ParseError).while(loading) }
      it { expect("{''}").to     fail_with(ParseError).while(loading) }
      it { expect('{""}').to     fail_with(ParseError).while(loading) }
    end
  end

  context 'not balanced bracket sequence' do
    context 'of lists' do
      it { expect('[').to fail_with(ParseError).while(loading)    }
      it { expect(']').to fail_with(ParseError).while(loading)    }

      it { expect('[[').to fail_with(ParseError).while(loading)   }
      it { expect(']]').to fail_with(ParseError).while(loading)   }
      it { expect('][').to fail_with(ParseError).while(loading)   }

      it { expect('[[]').to fail_with(ParseError).while(loading)  }
      it { expect('[]]').to fail_with(ParseError).while(loading)  }

      it { expect('[]][').to fail_with(ParseError).while(loading) }
      it { expect('][[]').to fail_with(ParseError).while(loading) }
    end

    context 'of dicts' do
      it { expect('{').to fail_with(ParseError).while(loading)  }
      it { expect('}').to fail_with(ParseError).while(loading)  }

      it { expect('{{').to fail_with(ParseError).while(loading) }
      it { expect('}}').to fail_with(ParseError).while(loading) }
      it { expect('}{').to fail_with(ParseError).while(loading) }
    end

    context 'of strings' do
      it { expect("'").to fail_with(ParseError).while(loading)   }
      it { expect('"').to fail_with(ParseError).while(loading)   }
      it { expect("'''").to fail_with(ParseError).while(loading) }
      it { expect('"""').to fail_with(ParseError).while(loading) }
    end

    context 'mixed [] and {}' do
      context 'inside list' do
        it { expect('[{]').to fail_with(ParseError).while(loading) }
        it { expect('[}]').to fail_with(ParseError).while(loading) }
      end

      context 'inside dict' do
        it { expect("{'key': [}").to fail_with(ParseError).while(loading) }
        it { expect("{'key': ]}").to fail_with(ParseError).while(loading) }
      end
    end
  end

  context 'smoke tests inside deeply nested structure' do
    include_examples 'values inside parsing context',
      wrap_actual:   ->(given_str)    { %|  [1,[ { 'key' : #{given_str} } , 2,  [ "3"  ]], 4 ]| },
      wrap_expected: ->(expected_obj) { [1, [{'key' => expected_obj}, 2, ['3']], 4] }
  end
end
# rubocop:enable Style/LambdaCall
