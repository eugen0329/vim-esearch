# frozen_string_literal: true

require 'spec_helper'

describe VimlValue::Parser do
  include VimlValue::AST::Sexp
  include Helpers::VimlValue

  subject(:parsing) do
    ->(value) { VimlValue::Parser.new(VimlValue::Lexer.new).parse(value) }
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

  it { expect('').to become(nil).after(parsing) }

  context 'scalars' do
    it { expect('1').to       become(s(:numeric, 1)).after(parsing)     }
    it { expect('1.2').to     become(s(:numeric, 1.2)).after(parsing)   }
    it { expect('"str"').to   become(s(:string,  'str')).after(parsing) }
    it { expect('v:null').to  become(s(:null,    nil)).after(parsing)   }
    it { expect('v:true').to  become(s(:boolean, true)).after(parsing)  }
    it { expect('v:false').to become(s(:boolean, false)).after(parsing) }
  end

  context 'collections' do
    it { expect('[1.2]').to   become(s(:list, s(:numeric, 1.2))).after(parsing) }
    it do
      expect('{"key_str": 1.2}').to become(
        s(:dict,
          s(:pair, s(:string, 'key_str'), s(:numeric, 1.2)))
      ).after(parsing)
    end
  end

  context 'special' do
    it { expect('[...]').to          become(s(:list_recursive_ref)).after(parsing) }
    it { expect('{...}').to          become(s(:dict_recursive_ref)).after(parsing) }
    it { expect('function("tr")').to become(s(:funcref, 'tr')).after(parsing)      }
  end
end
