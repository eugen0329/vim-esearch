# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#util' do
  include VimlValue::SerializationHelpers

  describe '#has_upper' do
    subject(:has_upper) do
      lambda do |text|
        editor.echo! func('esearch#util#has_upper', text)
      end
    end

    shared_examples 'it works with any encoding' do
      describe 'detection' do
        context 'when ascii' do
          it { expect(has_upper.call('aab')).to eq(0) }
          it { expect(has_upper.call('aAb')).to eq(1) }
        end

        context 'when unicode' do
          it { expect(has_upper.call('aσb')).to eq(0) }
          it { expect(has_upper.call('aΣb')).to eq(1) }
        end
      end

      describe 'options restoring' do
        it do
          expect { has_upper.call('a') }
            .not_to change { editor.echo(var('&ignorecase')) }
        end
      end
    end

    context 'when ignorecase' do
      before { editor.command! 'set ignorecase' }

      it_behaves_like 'it works with any encoding'
    end

    context 'when noignorecase' do
      before { editor.command! 'set noignorecase' }

      it_behaves_like 'it works with any encoding'
    end
  end
end
