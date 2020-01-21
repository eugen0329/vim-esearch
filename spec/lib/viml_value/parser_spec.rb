# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Parser do
  include VimlValue::AST::Sexp
  include Helpers::VimlValue

  describe '#parse' do
    ParseError = VimlValue::ParseError
    subject(:parsing) do
      ->(value) { VimlValue::Parser.new(VimlValue::Lexer.new(value)).parse }
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

    context 'nothing' do
      it { expect('').to become(nil).after(parsing) }
    end

    context 'literals' do
      it { expect('1').to              become(s(:numeric, 1)).after(parsing)         }
      it { expect('1.2').to            become(s(:numeric, 1.2)).after(parsing)       }
      it { expect('"str1"').to         become(s(:string,  'str1')).after(parsing)    }
      it { expect("'str2'").to         become(s(:string,  'str2')).after(parsing)    }
      it { expect('v:null').to         become(s(:null,    nil)).after(parsing)       }
      it { expect('v:true').to         become(s(:boolean, true)).after(parsing)      }
      it { expect('v:false').to        become(s(:boolean, false)).after(parsing)     }
      it { expect('v:false').to        become(s(:boolean, false)).after(parsing)     }
      it { expect('[...]').to          become(s(:list_recursive_ref)).after(parsing) }
      it { expect('{...}').to          become(s(:dict_recursive_ref)).after(parsing) }
      it { expect('function("tr")').to become(s(:funcref, 'tr')).after(parsing)      }
      it { expect("function('tr')").to become(s(:funcref, 'tr')).after(parsing)      }
    end

    context 'list' do
      context 'blank' do
        it { expect('[]').to     become(s(:list)).after(parsing)      }
        it { expect('[,]').to    fail_with(ParseError).while(parsing) }
      end

      context 'non-blank' do
        it { expect('[1.2]').to  become(s(:list, s(:numeric, 1.2))).after(parsing) }
        it { expect('[1.2,]').to become(s(:list, s(:numeric, 1.2))).after(parsing) }
        it { expect('[1,,]').to  fail_with(ParseError).while(parsing)              }
      end
    end

    context 'dict' do
      context 'blank' do
        it { expect('{}').to  become(s(:dict)).after(parsing)      }
        it { expect('{,}').to fail_with(ParseError).while(parsing) }
      end

      context 'non-blank' do
        let(:expected) { s(:dict, s(:pair, s(:string, 'key_str'), s(:numeric, 1.2))) }

        it { expect('{"key_str": 1.2}').to   become(expected).after(parsing)      }
        it { expect('{"key_str": 1.2,}').to  become(expected).after(parsing)      }
        it { expect('{"key_str": 1.2,,]').to fail_with(ParseError).while(parsing) }
        it { expect('{"key_str":,}').to      fail_with(ParseError).while(parsing) }
      end

      context 'incorrect pairs' do
        it { expect('{1}').to      fail_with(ParseError).while(parsing) }
        it { expect('{1: 1}').to   fail_with(ParseError).while(parsing) }
        it { expect("{1: '1'}").to fail_with(ParseError).while(parsing) }
        it { expect("{''}").to     fail_with(ParseError).while(parsing) }
        it { expect('{""}').to     fail_with(ParseError).while(parsing) }
      end
    end

    context 'not balanced bracket sequences' do
      context 'of lists' do
        it { expect('[').to    fail_with(ParseError).while(parsing) }
        it { expect(']').to    fail_with(ParseError).while(parsing) }

        it { expect('[[').to   fail_with(ParseError).while(parsing) }
        it { expect(']]').to   fail_with(ParseError).while(parsing) }
        it { expect('][').to   fail_with(ParseError).while(parsing) }

        it { expect('[[]').to  fail_with(ParseError).while(parsing) }
        it { expect('[]]').to  fail_with(ParseError).while(parsing) }

        it { expect('[]][').to fail_with(ParseError).while(parsing) }
        it { expect('][[]').to fail_with(ParseError).while(parsing) }
      end

      context 'of dicts' do
        it { expect('{').to  fail_with(ParseError).while(parsing) }
        it { expect('}').to  fail_with(ParseError).while(parsing) }

        it { expect('{{').to fail_with(ParseError).while(parsing) }
        it { expect('}}').to fail_with(ParseError).while(parsing) }
        it { expect('}{').to fail_with(ParseError).while(parsing) }
      end

      context 'of strings' do
        it { expect("'").to   fail_with(ParseError).while(parsing) }
        it { expect('"').to   fail_with(ParseError).while(parsing) }
        it { expect("'''").to fail_with(ParseError).while(parsing) }
        it { expect('"""').to fail_with(ParseError).while(parsing) }
      end

      context 'mixed [] and {}' do
        context 'inside list' do
          it { expect('[{]').to fail_with(ParseError).while(parsing) }
          it { expect('[}]').to fail_with(ParseError).while(parsing) }
        end

        context 'inside dict' do
          it { expect("{'key_str': [}").to fail_with(ParseError).while(parsing) }
          it { expect("{'key_str': ]}").to fail_with(ParseError).while(parsing) }
        end
      end
    end

    context 'sequential calling described method' do
      let(:value) { '[1]' }
      subject(:parser) { VimlValue::Parser.new(VimlValue::Lexer.new(value)) }

      it { expect(subject.parse).to eq(subject.parse) }
    end
  end
end
