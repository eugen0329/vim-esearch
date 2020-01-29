# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Parser do
  include VimlValue::AST::Sexp
  include Helpers::VimlValue

  ParseError ||= VimlValue::ParseError

  describe '#parse' do
    let(:allow_toplevel_literals) { true }
    let(:options) { {allow_toplevel_literals: allow_toplevel_literals} }
    subject(:parse_proc) do
      lambda do |value|
        VimlValue::Parser.new(VimlValue::Lexer.new(value), **options).parse
      end
    end

    def be_parsed_as(expected)
      Helpers::VimlValue::BeParsedAs.new(expected, &parse_proc)
    end

    def fail_parsing_with(expected)
      Helpers::VimlValue::FailParsingWith.new(expected, &parse_proc)
    end

    context 'nothing' do
      it { expect('').to be_parsed_as(nil) }
    end

    context 'literals' do
      it { expect('1').to              be_parsed_as(s(:numeric, 1))         }
      it { expect('1.2').to            be_parsed_as(s(:numeric, 1.2))       }
      it { expect('"str1"').to         be_parsed_as(s(:string,  'str1'))    }
      it { expect("'str2'").to         be_parsed_as(s(:string,  'str2'))    }
      it { expect('v:null').to         be_parsed_as(s(:null,    nil))       }
      it { expect('v:none').to         be_parsed_as(s(:none))               }
      it { expect('None').to           be_parsed_as(s(:none))               }
      it { expect('v:true').to         be_parsed_as(s(:boolean, true))      }
      it { expect('v:false').to        be_parsed_as(s(:boolean, false))     }
      it { expect('[...]').to          be_parsed_as(s(:list_recursive_ref)) }
      it { expect('{...}').to          be_parsed_as(s(:dict_recursive_ref)) }

      it { expect('function("tr")').to be_parsed_as(s(:funcref, s(:string, 'tr'))) }
      it { expect("function('tr')").to be_parsed_as(s(:funcref, s(:string, 'tr'))) }
      it do
        expect("function('fn', 1)")
          .to be_parsed_as(s(:funcref, s(:string, 'fn'), s(:numeric, 1)))
      end
      it do
        expect("function('fn', [1])")
          .to be_parsed_as(s(:funcref, s(:string, 'fn'), s(:list, s(:numeric, 1))))
      end
    end

    context 'list' do
      context 'blank' do
        it { expect('[]').to  be_parsed_as(s(:list)) }
        it { expect('[,]').to fail_parsing_with(ParseError) }
      end

      context 'non-blank' do
        it { expect('[1.2]').to  be_parsed_as(s(:list, s(:numeric, 1.2))) }
        it { expect('[1.2,]').to be_parsed_as(s(:list, s(:numeric, 1.2))) }
        it { expect('[1,,]').to  fail_parsing_with(ParseError)            }
      end
    end

    context 'dict' do
      context 'blank' do
        it { expect('{}').to  be_parsed_as(s(:dict)) }
        it { expect('{,}').to fail_parsing_with(ParseError) }
      end

      context 'non-blank' do
        let(:expected) { s(:dict, s(:pair, s(:string, 'key_str'), s(:numeric, 1.2))) }

        it { expect('{"key_str": 1.2}').to   be_parsed_as(expected)      }
        it { expect('{"key_str": 1.2,}').to  be_parsed_as(expected)      }
        it { expect('{"key_str": 1.2,,]').to fail_parsing_with(ParseError) }
        it { expect('{"key_str":,}').to      fail_parsing_with(ParseError) }
      end

      context 'incorrect pairs' do
        it { expect('{1}').to      fail_parsing_with(ParseError) }
        it { expect('{1: 1}').to   fail_parsing_with(ParseError) }
        it { expect("{1: '1'}").to fail_parsing_with(ParseError) }
        it { expect("{''}").to     fail_parsing_with(ParseError) }
        it { expect('{""}').to     fail_parsing_with(ParseError) }
      end
    end

    context 'not balanced bracket sequences' do
      context 'of lists' do
        it { expect('[').to    fail_parsing_with(ParseError) }
        it { expect(']').to    fail_parsing_with(ParseError) }

        it { expect('[[').to   fail_parsing_with(ParseError) }
        it { expect(']]').to   fail_parsing_with(ParseError) }
        it { expect('][').to   fail_parsing_with(ParseError) }

        it { expect('[[]').to  fail_parsing_with(ParseError) }
        it { expect('[]]').to  fail_parsing_with(ParseError) }

        it { expect('[]][').to fail_parsing_with(ParseError) }
        it { expect('][[]').to fail_parsing_with(ParseError) }
      end

      context 'of dicts' do
        it { expect('{').to  fail_parsing_with(ParseError) }
        it { expect('}').to  fail_parsing_with(ParseError) }

        it { expect('{{').to fail_parsing_with(ParseError) }
        it { expect('}}').to fail_parsing_with(ParseError) }
        it { expect('}{').to fail_parsing_with(ParseError) }
      end

      context 'of strings' do
        it { expect("'").to   fail_parsing_with(ParseError) }
        it { expect('"').to   fail_parsing_with(ParseError) }
        it { expect("'''").to fail_parsing_with(ParseError) }
        it { expect('"""').to fail_parsing_with(ParseError) }
      end

      context 'inside list' do
        context 'inside list' do
          it { expect('[{]').to fail_parsing_with(ParseError) }
          it { expect('[}]').to fail_parsing_with(ParseError) }
        end

        context 'inside dict' do
          it { expect("{'key_str': [}").to fail_parsing_with(ParseError) }
          it { expect("{'key_str': ]}").to fail_parsing_with(ParseError) }
        end
      end
    end

    context 'sequential calling of described method' do
      let(:value) { '[1]' }
      subject(:parser) { VimlValue::Parser.new(VimlValue::Lexer.new(value)) }

      it { expect(parser.parse).to eq(parser.parse) }
    end
  end
end
