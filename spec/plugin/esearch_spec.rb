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
      puts "\n"*2, "#"*10, "B:ESEARCH.without('request')"
      dump('b:esearch.without("request")')
      puts "\n"*2, "#"*10, "REQUEST"
      dump('b:esearch.request')
      puts "\n"*2, "#"*10, "RTP"
      dump('&rtp')

      puts "\n"*2, "#"*10, "[UPDATETIME]"
      dump('&ut')

      puts "\n"*2, "#"*10, "SCRIPTNAMES"
      puts cmd('scriptnames')

      puts "\n"*2, "#"*10, "au User"
      puts cmd('au User')

      sc = expr("esearch#backend#vimproc#scope()")
      s = expr("esearch#backend#vimproc#sid()")
      puts "\n"*2, "#"*10, "s:completed(s:requests[0])"
      puts expr("#{s}completed(#{sc}.requests[0])")
      puts "\n"*2, "#"*10, "[len(request.data), request.data_ptr, has ->, request.out_finish()]"
      puts cmd("echo [len(#{sc}.requests[0].data)]")
      puts cmd("echo [#{sc}.requests[0].data_ptr]")
      puts cmd("echo has_key(#{sc}.requests[0], 'out_finish')")
      puts cmd("echo [#{sc}.requests[0].out_finish()]")
      dump('g:test')
    end
  end

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
      expect { line(1) =~ /Finish/i }.to become_true_within(20.second), -> { "Expected first line to match /Finish/, got `#{line(1)}`" }
      expect(bufname("%")).to match(/Search/)
    end

    # it 'fails with adapter error' do
    #   press ':call esearch#init()<Enter><C-o><C-r>(<Enter>'
    #   expect { line(1) =~ /Error/i }.to become_true_within(2.second)
    #   expect(bufname("%")).to match(/Search/i)
    # end
  end
end
