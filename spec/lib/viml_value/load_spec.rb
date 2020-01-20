# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Style/LambdaCall
describe 'VimlValue#load' do
  include VimlValue::SerializationHelpers
  include Helpers::VimlValue::Convert

  alias_matcher :be_loaded_as,     :be_converted_by_calling_subject_as
  alias_matcher :raise_on_loading, :raise_on_converting_by_calling_subject

  subject do
    ->(value) { VimlValue.load(value, allow_toplevel_literals: true) }
  end

  # To reuse tests for loading value inside different parsing contexts
  # (like value, [value], {'key': value} etc.)
  shared_examples 'wrapped value' do |wrap, wrap_result|
    context 'integer' do
      it { expect(wrap.('0')).to  be_loaded_as(wrap_result.(0))  }
      it { expect(wrap.('1')).to  be_loaded_as(wrap_result.(1))  }
      it { expect(wrap.('-2')).to be_loaded_as(wrap_result.(-2)) }
    end

    context 'float' do
      # from vim :help floating-point-format
      it { expect(wrap.('0.0')).to         be_loaded_as(wrap_result.(0.0))         }
      it { expect(wrap.('123.456')).to     be_loaded_as(wrap_result.(123.456))     }
      it { expect(wrap.('+0.0001')).to     be_loaded_as(wrap_result.(0.0001))      }
      it { expect(wrap.('55.0')).to        be_loaded_as(wrap_result.(55.0))        }
      it { expect(wrap.('-0.123')).to      be_loaded_as(wrap_result.(-0.123))      }
      it { expect(wrap.('1.234e03')).to    be_loaded_as(wrap_result.(1.234e03))    }
      it { expect(wrap.('1.0E-6')).to      be_loaded_as(wrap_result.(1.0E-6))      }
      it { expect(wrap.('-3.1416e+88')).to be_loaded_as(wrap_result.(-3.1416e+88)) }
    end

    context 'function references' do
      it { expect(wrap.("function('tr')")).to  be_loaded_as(wrap_result.(funcref('tr'))) }
      it { expect(wrap.("function ('tr')")).to be_loaded_as(wrap_result.(funcref('tr'))) }
      it { expect(wrap.('function("tr")')).to  be_loaded_as(wrap_result.(funcref('tr'))) }

      it { expect(wrap.('function')).to      raise_on_loading(VimlValue::ParseError) }

      it { expect(wrap.('function')).to      raise_on_loading(VimlValue::ParseError) }
      it { expect(wrap.('function()')).to    raise_on_loading(VimlValue::ParseError) }
      it { expect(wrap.('function(1)')).to   raise_on_loading(VimlValue::ParseError) }
      it { expect(wrap.('function({})')).to  raise_on_loading(VimlValue::ParseError) }
      it { expect(wrap.('function([])')).to  raise_on_loading(VimlValue::ParseError) }
      it { expect(wrap.('function("tr"')).to raise_on_loading(VimlValue::ParseError) }
      it { expect(wrap.('function"tr")')).to raise_on_loading(VimlValue::ParseError) }
      it { expect(wrap.('function "tr"')).to raise_on_loading(VimlValue::ParseError) }
    end

    context 'boolean' do
      it { expect(wrap.('v:true')).to be_loaded_as(wrap_result.(true)) }
      it { expect(wrap.('v:false')).to be_loaded_as(wrap_result.(false)) }
    end

    context 'v:null' do
      it { expect(wrap.('v:null')).to be_loaded_as(wrap_result.(nil)) }
    end

    context 'recursive references' do
      it { expect(wrap.('{...}')).to be_loaded_as(wrap_result.(dict_recursive_ref)) }
      it { expect(wrap.('[...]')).to be_loaded_as(wrap_result.(list_recursive_ref)) }
    end

    context 'string' do
      it { expect(wrap.("'1'")).to be_loaded_as(wrap_result.('1')) }
      it { expect(wrap.('"1"')).to be_loaded_as(wrap_result.('1')) }

      # some of them are tokenized correctly, but cause parse errors, so it
      # should be tested on parser level
      context 'escaping' do
        context 'of surrounding quotes' do
          context 'with backslash' do
            context 'single quote' do
              it { expect(wrap.("'\\''")).to  raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("'\\'")).to   be_loaded_as(wrap_result.('\\'))        }
              it { expect(wrap.("'\\\\'")).to be_loaded_as(wrap_result.('\\\\'))      }
            end

            context 'double quote' do
              it { expect(wrap.('"\\""')).to  be_loaded_as(wrap_result.('"'))         }
              it { expect(wrap.('"\\"')).to   raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('"\\\\"')).to be_loaded_as(wrap_result.('\\')) }
            end
          end

          context 'with duplication' do
            context 'single-quoted' do
              it { expect(wrap.("''''")).to   be_loaded_as(wrap_result.("'"))  }
              it { expect(wrap.("''''''")).to be_loaded_as(wrap_result.("''")) }
            end

            context 'double-quoted' do
              it { expect(wrap.('""""')).to   raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('""""""')).to raise_on_loading(VimlValue::ParseError) }
            end

            context 'mixing single and double-quoted' do
              # Have to be tested in terms of integration as some quotes escaping
              # is valid in terms of tokenization, but invalid as a viml value
              # A bit verbose, but it helps to understand how tricky escaping works
              # in vim and to ensure that everything works properly
              it { expect(wrap.('\\"""""')).to raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('"\\""""')).to raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('""\\"""')).to raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('"""\\""')).to raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('""""\\"')).to raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("\\'''''")).to raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("'\\''''")).to raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("''\\'''")).to raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("'''\\''")).to raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("''''\\'")).to raise_on_loading(VimlValue::ParseError) }

              it { expect(wrap.('\\""""')).to  raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('"\\"""')).to  raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('""\\""')).to  raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('"""\\"')).to  raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('""""\\')).to  raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("\\''''")).to  raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("'\\'''")).to  be_loaded_as(wrap_result.("\\'")) }
              it { expect(wrap.("''\\''")).to  raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("'''\\'")).to  be_loaded_as(wrap_result.("'\\")) }
              it { expect(wrap.("''''\\")).to  raise_on_loading(VimlValue::ParseError) }

              it { expect(wrap.('\\"""')).to   raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('"\\""')).to   be_loaded_as(wrap_result.('"')) }
              it { expect(wrap.('""\\"')).to   raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.('"""\\')).to   raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("\\'''")).to   raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("'\\''")).to   raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("''\\'")).to   raise_on_loading(VimlValue::ParseError) }
              it { expect(wrap.("'''\\")).to   raise_on_loading(VimlValue::ParseError) }

              it { expect(wrap.(%q|"\\'"|)).to be_loaded_as(wrap_result.("'")) }
              it { expect(wrap.("'\\'''")).to  be_loaded_as(wrap_result.("\\'")) }
              it { expect(wrap.("'''\\'")).to  be_loaded_as(wrap_result.("'\\")) }
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

    context 'nothing' do
      it { expect('').to be_loaded_as(nil) }
    end
  end

  context 'inside list' do
    include_examples 'wrapped value',
      ->(given_str)    { "[#{given_str}]" },
      ->(expected_obj) { [expected_obj] }

    it { expect('[]').to be_loaded_as([]) }
    it { expect('1,2').to raise_on_loading(VimlValue::ParseError) }

    context 'trailing comma' do
      it { expect('[1,]').to  be_loaded_as([1]) }
      it { expect('[1,,]').to raise_on_loading(VimlValue::ParseError) }
      it { expect('[,]').to   raise_on_loading(VimlValue::ParseError) }
    end
  end

  context 'inside dict' do
    include_examples 'wrapped value',
      ->(given_str)    { "{'key': #{given_str}}" },
      ->(expected_obj) { {'key' => expected_obj} }

    it { expect('{}').to be_loaded_as({}) }
    it { expect('"key": 1').to raise_on_loading(VimlValue::ParseError) }

    context 'trailing comma' do
      it { expect('{"key": 1,}').to  be_loaded_as('key' => 1) }
      it { expect('{"key": 1,,]').to raise_on_loading(VimlValue::ParseError) }
      it { expect('{"key":,}').to    raise_on_loading(VimlValue::ParseError) }
      it { expect('{,}').to          raise_on_loading(VimlValue::ParseError) }
    end

    context 'incorrect pairs' do
      it { expect('{1}').to      raise_on_loading(VimlValue::ParseError) }
      it { expect('{1: 1}').to   raise_on_loading(VimlValue::ParseError) }
      it { expect("{1: '1'}").to raise_on_loading(VimlValue::ParseError) }
      it { expect("{''}").to     raise_on_loading(VimlValue::ParseError) }
      it { expect('{""}').to     raise_on_loading(VimlValue::ParseError) }
    end
  end

  context 'not balanced bracket sequence' do
    context 'of lists' do
      it { expect('[').to raise_on_loading(VimlValue::ParseError) }
      it { expect(']').to raise_on_loading(VimlValue::ParseError) }

      it { expect('[[').to raise_on_loading(VimlValue::ParseError) }
      it { expect(']]').to raise_on_loading(VimlValue::ParseError) }
      it { expect('][').to raise_on_loading(VimlValue::ParseError) }

      it { expect('[[]').to raise_on_loading(VimlValue::ParseError) }
      it { expect('[]]').to raise_on_loading(VimlValue::ParseError) }

      it { expect('[]][').to raise_on_loading(VimlValue::ParseError) }
      it { expect('][[]').to raise_on_loading(VimlValue::ParseError) }
    end

    context 'of dicts' do
      it { expect('{').to raise_on_loading(VimlValue::ParseError) }
      it { expect('}').to raise_on_loading(VimlValue::ParseError) }

      it { expect('{{').to raise_on_loading(VimlValue::ParseError) }
      it { expect('}}').to raise_on_loading(VimlValue::ParseError) }
      it { expect('}{').to raise_on_loading(VimlValue::ParseError) }
    end

    context 'of strings' do
      it { expect("'").to raise_on_loading(VimlValue::ParseError) }
      it { expect('"').to raise_on_loading(VimlValue::ParseError) }
      it { expect("'''").to raise_on_loading(VimlValue::ParseError) }
      it { expect('"""').to raise_on_loading(VimlValue::ParseError) }
    end

    context 'mixed [] and {}' do
      context 'inside list' do
        it { expect('[{]').to raise_on_loading(VimlValue::ParseError) }
        it { expect('[}]').to raise_on_loading(VimlValue::ParseError) }
      end

      context 'inside dict' do
        it { expect("{'key': [}").to raise_on_loading(VimlValue::ParseError) }
        it { expect("{'key': ]}").to raise_on_loading(VimlValue::ParseError) }
      end
    end
  end

  context 'smoke tests inside deeply nested structure' do
    include_examples 'wrapped value',
      ->(given_str)    { %|  [1,[ { 'key' : #{given_str} } , 2,  [ "3"  ]], 4 ]| },
      ->(expected_obj) { [1, [{'key' => expected_obj}, 2, ['3']], 4] }
  end
end
# rubocop:enable Style/LambdaCall
