require 'spec_helper'
require 'json'

context 'esearch' do
  let(:win_open_quota) { 4 }

  after(:each) do |example|
    unless example.exception.nil?
      cmd('let g:prettyprint_width = 160')

      puts 'FIRST LINE:', line(1)
      puts "PWD: #{expr('$PWD')}, GETCWD(): #{expr('getcwd()')}"
      puts "Last buf #{expr('bufnr("$")')}, curr buf  #{expr('bufnr("%")')}"


      puts "\n"*2, "#"*10, "G:ESEARCH"
      dump('g:esearch')
      puts "\n"*2, "#"*10, "B:ESEARCH"
      dump('b:esearch')
      puts "\n"*2, "#"*10, "REQUEST"
      dump('b:esearch.request')
      puts "\n"*2, "#"*10, "RTP"
      dump('&rtp')

      puts "\n"*2, "#"*10, "SCRIPTNAMES"
      puts cmd('scriptnames')

      puts "\n"*2, "#"*10, "[UPDATETIME]"
      dump('&ut')
    end
  end

  it 'can be tested' do
    expect(has('clientserver')).to be_truthy
    meet_requirements = has('nvim') || bool_expr('esearch#util#has_vimproc()')
    expect(meet_requirements).to be_truthy
  end

  describe '#init' do
    it 'works without args' do
      press 'cd spec/fixtures/plugin/<Enter>'
      press ':call esearch#init()<Enter>asd<Enter>'

      expected = expect do
        press("<Nop>") # to skip "Press ENTER or type command to continue" prompt
        exists('b:esearch')
      end
      expected.to become_true_within(win_open_quota.second),
        "Expected ESearch win will be opened in #{win_open_quota}"

      expect(expr('b:esearch.cwd')).to eq(expr('$PWD'))
      expect { line(1) =~ /Finish/i }.to become_true_within(120.second), -> { "Expected first line to match /Finish/, got `#{line(1)}`" }
      expect(bufname("%")).to match(/Search/)
    end

    # it 'fails with adapter error' do
    #   press ':call esearch#init()<Enter><C-o><C-r>(<Enter>'
    #   expect { line(1) =~ /Error/i }.to become_true_within(2.second)
    #   expect(bufname("%")).to match(/Search/i)
    # end
  end
end
