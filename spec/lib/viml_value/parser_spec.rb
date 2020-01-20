# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Parser do
  include Helpers::VimlValue::Parse
  include VimlValue::AST::Sexp
  extend Helpers::VimlValue::DefineSharedMatchers

  define_transformation_matcher!(:be_parsed_as, verb: 'parse')
  define_raise_on_transformation_matcher!(:raise_on_parse, verb: 'parsing')

  subject do
    proc { |actual| VimlValue::Parser.new(VimlValue::Lexer.new).parse(actual) }
  end

  it { expect('').to be_parsed_as(nil) }

  context 'scalars' do
    it { expect('1').to       be_parsed_as(s(:numeric, 1))     }
    it { expect('1.2').to     be_parsed_as(s(:numeric, 1.2))   }
    it { expect('"str"').to   be_parsed_as(s(:string,  'str')) }
    it { expect('v:null').to  be_parsed_as(s(:null,    nil))   }
    it { expect('v:true').to  be_parsed_as(s(:boolean, true))  }
    it { expect('v:false').to be_parsed_as(s(:boolean, false)) }
  end

  context 'collections' do
    it { expect('[1.2]').to   be_parsed_as(s(:list,    s(:numeric, 1.2))) }
    it do
      expect('{"key_str": 1.2}').to be_parsed_as(
        s(:dict,
          s(:pair, s(:string, 'key_str'), s(:numeric, 1.2)))
      )
    end
  end

  context 'special' do
    it { expect('[...]').to          be_parsed_as(s(:list_recursive_ref)) }
    it { expect('{...}').to          be_parsed_as(s(:dict_recursive_ref)) }
    it { expect('function("tr")').to be_parsed_as(s(:funcref, 'tr'))      }
  end
end
