# frozen_string_literal: true

RSpec.shared_context 'inherited from Editor::Read::Base' do
  shared_examples '#with_ignore_cache' do
    around { |e| subject.with_ignore_cache(&e) }

    context '#echo call' do
      let(:calls_count) { 2 }

      it "doesn't cache echo calls" do
        expect(vim).to receive(:echo).exactly(calls_count).and_call_original

        calls_count.times { subject.echo(func('abs', -1)).to_s }
      end
    end
  end

  shared_examples '#handle_state_change!' do
    let(:cache_enabled) { true }

    it 'clears cache' do
      expect(vim).to receive(:echo).twice.and_call_original
      2.times { subject.echo(func('abs', -1)).to_s }
      subject.handle_state_change!
      2.times { subject.echo(func('abs', -1)).to_s }
    end
  end
end
