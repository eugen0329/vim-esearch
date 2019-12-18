RSpec.shared_examples 'an abortable backend' do |backend|
  let(:adapter) { 'ag' }
  let(:search_string) { '550e8400-e29b-41d4-a716-446655440000' }
  let(:out) { 'win' }

  around do |example|
    esearch_settings(backend: backend, adapter: adapter, out: out)
    vim_let("g:esearch#adapter##{adapter}#bin",
            "'sh #{working_directory}/spec/support/bin/search_in_infinite_random_stdin.sh #{adapter}'")
    expect(ps_commands).not_to include(search_string) # prevent false positive results

    example.run

    `ps aux | grep #{search_string} | awk '$0=$2' | xargs kill`
    vim_let("g:esearch#adapter##{adapter}#bin", "'#{adapter}'")
    cmd('close!') if bufname("%") =~ /Search/
  end

  context '#out#win' do
    let(:out) { 'win' }

    it 'aborts on bufdelete' do
      press ":call esearch#init({'cwd': ''})<Enter>#{search_string}<Enter>"
      wait_for_search_start
      expect { ps_commands.include?(search_string) }.to become_true_within(10.seconds)
      wait_for_search_freezed

      delete_current_buffer
      expect { !ps_commands.include?(search_string) }.to become_true_within(10.seconds)
    end

    it 'aborts on search restart' do
      2.times do
        press ":call esearch#init({'cwd': ''})<Enter>#{search_string}<Enter>"
        wait_for_search_start
        expect { ps_commands.include?(search_string) }.to become_true_within(10.seconds)
        wait_for_search_freezed
      end

      expect { ps_commands_without_sh.scan(/#{search_string}/).count == 1 }
        .to become_true_within(10.seconds)
    end
  end

  context '#out#qflist' do
    let(:out) { 'qflist' }

    it 'aborts on bufdelete' do
      press ":call esearch#init({'cwd': ''})<Enter>#{search_string}<Enter>"
      wait_for_qickfix_enter
      expect { ps_commands.include?(search_string) }.to become_true_within(10.seconds)
      wait_for_search_freezed
      expect { ps_commands.include?(search_string) } .to become_true_within(10.seconds)

      delete_current_buffer
      expect { !ps_commands.include?(search_string) } .to become_true_within(10.seconds)
    end

    it 'aborts on search restart' do
      2.times do
        press ":call esearch#init({'cwd': ''})<Enter>#{search_string}<Enter>"
        wait_for_qickfix_enter
        expect { ps_commands.include?(search_string) }.to become_true_within(10.seconds)
        wait_for_search_freezed
      end

      expect { ps_commands_without_sh.scan(/#{search_string}/).count == 1 }
        .to become_true_within(10.seconds)
    end
  end

  include_context 'dumpable'
end
