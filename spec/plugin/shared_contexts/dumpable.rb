RSpec.shared_context "dumpable" do
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
      puts "\n"*2, "#"*10, "[len(request.data), request.data_ptr, exists ->, type ->, request.out_finish()]"
      puts cmd("echo [len(#{sc}.requests[0].data)]")
      puts cmd("echo [#{sc}.requests[0].data_ptr]")
      puts cmd("echo has_key(#{sc}.requests[0], 'out_finish')")
      puts cmd("echo [type(#{sc}.requests[0].out_finish)]")
      puts cmd("echo [#{sc}.requests[0].out_finish()]")
    end
  end
end
