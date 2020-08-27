# frozen_string_literal: true

RSpec.shared_context 'inherited from Editor::Read::Base' do
  shared_examples '#with_ignore_cache' do
    context 'return value' do
      let(:block_returned_value) { 42 }

      it do
        expect(subject.with_ignore_cache { block_returned_value })
          .to eq(block_returned_value)
      end
    end

    context 'inside the block' do
      around { |e| subject.with_ignore_cache(&e) }

      context '#echo call' do
        let(:calls_count) { 2 }

        before { expect(calls_count).to be > 1 } # verify the setup

        it "doesn't cache echo calls" do
          expect(vim)
            .to receive(:echo)
            .exactly(calls_count)
            .with('[abs(-1)]')
            .and_return('[1]')

          calls_count.times do
            expect(subject.echo(func('abs', -1))).to eq(1)
          end
        end
      end
    end
  end

  shared_examples '#invalidate_cache!' do
    let(:cache_enabled) { true }

    it 'clears cache' do
      expect(vim).to receive(:echo).twice.with('[abs(-1)]').and_return('[1]')
      2.times { subject.echo(func('abs', -1)).to_s }
      subject.invalidate_cache!
      2.times { subject.echo(func('abs', -1)).to_s }
    end
  end
end
