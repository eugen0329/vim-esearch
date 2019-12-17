RSpec.shared_examples 'an abortable backend' do |backend|
  let(:adapter) { 'ag' } # trick with urandom works only with grep
  let(:search_string) { '550e8400-e29b-41d4-a716-446655440000' }
  let(:out) { 'win' }

  before do
    esearch_settings(backend: backend, adapter: adapter, out: out)
    vim_let("g:esearch#adapter##{adapter}#bin", "'cat /dev/urandom | #{adapter}'")

  end
  after do
    `ps aux | grep #{search_string} | awk '$0=$2' | xargs kill`
  end

  context '#out#win' do
    let(:out) { 'win' }

    it 'aborts on bufdelete' do
      press ":call esearch#init({'cwd': ''})<Enter>#{search_string}<Enter>"
      wait_for_search_start
      expect { `ps aux`.include?(search_string) }.to become_true_within(10.seconds)
      wait_for_search_freezed

      delete_current_buffer
      expect { !`ps aux`.include?(search_string) }.to become_true_within(10.seconds)
    end

    it 'aborts on search restart' do
      2.times do
        press ":call esearch#init({'cwd': ''})<Enter>#{search_string}<Enter>"
        wait_for_search_start
        expect { `ps aux`.include?(search_string) }.to become_true_within(10.seconds)
        wait_for_search_freezed
      end

      expect { ps_aux_without_sh_delegate_command.scan(/#{search_string}/).count == 1 }
        .to become_true_within(10.seconds)
    end
  end

  context '#out#qflist' do
    let(:out) { 'qflist' }

    it 'aborts on bufdelete' do
      press ":call esearch#init({'cwd': ''})<Enter>#{search_string}<Enter>"
      wait_for_qickfix_enter
      expect { `ps aux`.include?(search_string) }.to become_true_within(10.seconds)
      wait_for_search_freezed
      expect { `ps aux`.include?(search_string) } .to become_true_within(10.seconds)

      delete_current_buffer
      expect { !`ps aux`.include?(search_string) } .to become_true_within(10.seconds)
    end

    it 'aborts on search restart' do
      2.times do
        press ":call esearch#init({'cwd': ''})<Enter>#{search_string}<Enter>"
        wait_for_qickfix_enter
        expect { `ps aux`.include?(search_string) }.to become_true_within(10.seconds)
        wait_for_search_freezed
      end

      expect { ps_aux_without_sh_delegate_command.scan(/#{search_string}/).count == 1 }
        .to become_true_within(10.seconds)
    end
  end

  include_context 'dumpable'
end
