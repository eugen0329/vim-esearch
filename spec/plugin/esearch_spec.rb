require 'spec_helper'

context 'esearch' do
  let(:win_open_quota) { 4 }
  

  it 'can be tested' do
    expect(has('clientserver')).to be_truthy
    meet_requirements = has('nvim') != 0 || expr('esearch#util#has_vimproc()') != 0
    expect(meet_requirements).to be_truthy
  end

  describe '#init' do
    it 'works without args' do
      # press ':call esearch#init()<Enter>asd<Enter>'

      cmd("let g:esearch = esearch#opts#new(exists('g:esearch') ? g:esearch : {})")
      cmd("let g:exp = { 'vim': 'lorem_ipsum', 'pcre': 'lorem_ipsum', 'literal': 'lorem_ipsum' }")
      cmd("let g:exp = esearch#regex#finalize(g:exp, g:esearch)")
      puts cmd("try | call esearch#init({'exp': g:exp}) | catch | echo v:exception | endtry")

      puts expr('bufnr("$")')

      expected = expect do
        press("<Nop>") # to skip "Press ENTER or type command to continue" prompt
        exists('b:esearch')
      end
      expected.to become_true_within(win_open_quota.second),
        "Expect ESearch win will be opened in #{win_open_quota}"

      puts expr('b:esearch.cwd')
      puts expr('$PWD')
      expect(expr('b:esearch.cwd')).to eq(expr('$PWD'))

      puts expr('&ut')
      expect { line(1) =~ /Finish/i }.to become_true_within(120.second)
      expect(bufname("%")).to match(/Search/)
    end

    # it 'fails with adapter error' do
    #   press ':call esearch#init()<Enter><C-o><C-r>(<Enter>'
    #   expect { line(1) =~ /Error/i }.to become_true_within(2.second)
    #   expect(bufname("%")).to match(/Search/i)
    # end
  end
end
