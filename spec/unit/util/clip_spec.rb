# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#util' do
  include VimlValue::SerializationHelpers

  describe '#clip' do
    subject(:clip) do
      lambda do |value, from, to|
        editor.echo func('esearch#util#clip', value, from, to)
      end
    end

    it { expect(clip.call(0, 1, 4)).to eq(1)   }
    it { expect(clip.call(1, 1, 4)).to eq(1)   }
    it { expect(clip.call(2, 1, 4)).to eq(2)   }
    it { expect(clip.call(3, 1, 4)).to eq(3)   }
    it { expect(clip.call(4, 1, 4)).to eq(4)   }
    it { expect(clip.call(5, 1, 4)).to eq(4)   }
  end
end
