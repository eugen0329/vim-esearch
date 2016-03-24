context 'esearch' do
  describe '#init' do
    it 'runs without args' do
      press ':call esearch#init()<Enter>asd<Enter>'
      expect { line(1) =~ /Finish/i }.to become_true_within(2.second), '123'
      expect(bufname("%")).to match(/Search/)
      expect(expr('b:esearch.cwd')).to eq(expr('getcwd()'))
    end

    it 'fails with adapter error' do
      press ':call esearch#init()<Enter><C-o><C-r>(<Enter>'
      expect { line(1) =~ /Error/i }.to become_true_within(2.second)
      expect(bufname("%")).to match(/Search/i)
    end
  end
end
