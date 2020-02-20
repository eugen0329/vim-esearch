# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#util' do
  include VimlValue::SerializationHelpers
  include Helpers::FileSystem

  describe '#ellipsize' do
    subject(:ellipsize) do
      lambda do |text, col, left, right, ellipsize|
        editor.echo func('esearch#util#ellipsize', text, col, left, right, ellipsize)
      end
    end

    context 'when enough room' do
      it "doesn't add ellipsis" do
        expect(ellipsize.call('aaaBBBccc', 5, 5, 5, '|')).to eq('aaaBBBccc')
      end
    end

    context 'when string is bigger then allowed' do
      it { expect(ellipsize.call('aaaBBBccc', 0, 2, 2, '|')).to eq('aaa|')   }
      it { expect(ellipsize.call('aaaBBBccc', 1, 2, 2, '|')).to eq('aaa|')   }
      it { expect(ellipsize.call('aaaBBBccc', 2, 2, 2, '|')).to eq('aaa|')   }
      it { expect(ellipsize.call('aaaBBBccc', 3, 2, 2, '|')).to eq('|aB|')   }
      it { expect(ellipsize.call('aaaBBBccc', 4, 2, 2, '|')).to eq('|BB|') }
      it { expect(ellipsize.call('aaaBBBccc', 5, 2, 2, '|')).to eq('|BB|') }
      it { expect(ellipsize.call('aaaBBBccc', 6, 2, 2, '|')).to eq('|Bc|') }
      it { expect(ellipsize.call('aaaBBBccc', 7, 2, 2, '|')).to eq('|ccc') }
      it { expect(ellipsize.call('aaaBBBccc', 8, 2, 2, '|')).to eq('|ccc') }
    end
  end
end
