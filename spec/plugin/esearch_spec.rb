require 'spec_helper'

context 'esearch' do
  let(:win_open_quota) { 4 }

  it 'can be tested' do
    expect(has('clientserver')).to be_truthy
    meet_requirements = has('nvim') || bool_expr('esearch#util#has_vimproc()')
    expect(meet_requirements).to be_truthy
  end

  describe '#init' do
    it 'works without args' do
      press ':cd $PWD<ENTER>'
      press ':cd spec/fixtures/plugin/<ENTER>'

      cmd "let g:esearch = { 'batch_size': 2, 'backend': 'vimproc', 'adapter': 'grep'}"

      press ':call esearch#init()<Enter>lorem<Enter>'

      expected = expect do
        press("<Nop>") # to skip "Press ENTER or type command to continue" prompt
        exists('b:esearch')
      end
      expected.to become_true_within(win_open_quota.second),
        "Expected ESearch win will be opened in #{win_open_quota}"

      expect(expr('b:esearch.cwd')).to eq(expr('getcwd()'))
      expect { line(1) =~ /Finish/i }.to become_true_within(10.second), -> { "Expected first line to match /Finish/, got `#{line(1)}`" }
      expect(bufname("%")).to match(/Search/)
    end
  end
end
