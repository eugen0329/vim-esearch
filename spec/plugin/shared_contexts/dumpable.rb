# frozen_string_literal: true

RSpec.shared_context 'dumpable' do
  after(:each) do |example|
    unless example.exception.nil?
      if vim.server.is_a?(VimrunnerNeovim::Server)
        puts `ls /tmp`
        puts `ps -A -o pid,command | sed 1d | grep nvim`
        if File.exist?(vim.server.verbose_log_file)
          puts 'VERBOSE log start', '*' * 10
          puts File.readlines(vim.server.logfile).to_a
          puts '*' * 10, 'VERBOSE log end'
        end

        if File.exist?('/tmp/esearch_log.txt')
          puts 'INTERNAL log start', '*' * 10
          puts File.readlines('/tmp/esearch_log.txt').to_a
          puts '*' * 10, 'INTERNAL log end'
        end

        if File.exist?(vim.server.nvim_log_file)
          puts 'vim.server.nvim_log_file log'
          puts 'vim.server.nvim_log_file log start', '*' * 10
          puts File.readlines(vim.server.nvim_log_file).to_a
          puts '*' * 10, 'vim.server.nvim_log_file log end'
        else
          puts '$NVIM_LOG_FILE is missing'
        end
      end

      press('j') # press j to close "Press ENTER or type command to continue" prompt
      puts ':messages', cmd('messages')

      cmd('let g:prettyprint_width = 160')

      puts 'Buffer content:', buffer_content
      puts "PWD: #{expr('$PWD')}, GETCWD(): #{expr('getcwd()')}"
      puts "Last buf #{expr('bufnr("$")')}, curr buf  #{expr('bufnr("%")')}"

      puts "\n" * 2, '#' * 10, 'RUNTIMEPATH'
      puts expr('&runtimepath')

      puts 'buffers:', cmd('ls!')

      if exists('*prettyprint#prettyprint')
        puts "\n" * 2, '#' * 10, 'G:ESEARCH'
        dump('g:esearch')
        puts "\n" * 2, '#' * 10, "B:ESEARCH.without('request')"
        dump('b:esearch.without("request")')
        puts "\n" * 2, '#' * 10, 'REQUEST'
        dump('b:esearch.request')
        puts "\n" * 2, '#' * 10, '[UPDATETIME]'
        dump('&ut')
      end

      puts "\n" * 2, '#' * 10, 'SCRIPTNAMES'
      puts cmd('scriptnames')

      puts "\n" * 2, '#' * 10, 'au User'
      puts cmd('au User')

      sc = expr('esearch#backend#vimproc#scope()')
      s = expr('esearch#backend#vimproc#sid()')
      puts "\n" * 2, '#' * 10, 's:completed(s:requests[0])'
      puts expr("#{s}completed(#{sc}.requests[0])")
      puts "\n" * 2, '#' * 10, '[len(request.data), request.data_ptr, exists ->, type ->, request.out_finish()]'
      puts cmd("echo [len(#{sc}.requests[0].data)]")
      puts cmd("echo [#{sc}.requests[0].data_ptr]")
      puts cmd("echo has_key(#{sc}.requests[0], 'out_finish')")
      puts cmd("echo [type(#{sc}.requests[0].out_finish)]")
      puts cmd("echo [#{sc}.requests[0].out_finish()]")
    end
  end
end
