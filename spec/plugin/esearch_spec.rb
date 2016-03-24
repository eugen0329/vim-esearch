require 'spec_helper'

context 'esearch' do

  it 'can be tested' do
    expect(has('clientserver')).to be_truthy
    meet_requirements = has('nvim') != 0 || expr('esearch#util#has_vimproc()') != 0
    expect(meet_requirements).to be_truthy
  end

  describe '#init' do
    it 'works without args' do
      press ':call esearch#init()<Enter>asd<Enter>'
      sleep 2
      puts exp('ls')
      expect { press("<Nop>");exists('b:esearch') }.to become_true_within(4.second)
      expect { line(1) =~ /Finish/i }.to become_true_within(2.second)
      expect(bufname("%")).to match(/Search/)
      expect(expr('b:esearch.cwd')).to eq(expr('$PWD'))
    end

    # it 'fails with adapter error' do
    #   press ':call esearch#init()<Enter><C-o><C-r>(<Enter>'
    #   expect { line(1) =~ /Error/i }.to become_true_within(2.second)
    #   expect(bufname("%")).to match(/Search/i)
    # end
  end
end
