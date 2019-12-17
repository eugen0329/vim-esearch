RSpec.shared_examples 'an abortable backend' do |backend|
  let(:adapter) { 'grep' } # trick with urandom works only with grep
  let(:search_string) { '550e8400-e29b-41d4-a716-446655440000' }
  # let(:search_string) { '1' }
  let(:out) { 'win' }

  before do
    esearch_settings(backend: backend, adapter: adapter, out: out)
    vim_let('g:esearch#adapter#grep#bin', "'cat /dev/urandom | #{adapter}'")
  end
  after do
    `ps aux | grep #{search_string} | awk '$0=$2' | xargs kill`
  end

  context '#out#win' do
    let(:out) { 'win' }

    xit 'aborts on bufdelete' do
      press ":call esearch#init({'cwd': '/dev/urandom'})<Enter>#{search_string}<Enter>"
      wait_search_start

      expect { `ps aux`.include?(search_string) }
        .to become_true_within(10.seconds)

      # From :help bdelete
      #   Unload buffer [N] (default: current buffer) and delete it from the buffer list.
      press ':bdelete<Enter>'

      expect { !`ps aux`.include?(search_string) }
        .to become_true_within(10.seconds)
    end

    it 'aborts on search restart' do
      2.times do
        press ":call esearch#init()<Enter>#{search_string}<Enter>"
        wait_search_start

        expect { line(1) =~ /Finish/i }.not_to become_true_within(5.second)
      end

      expect { ps_aux_without_sh_delegate_command.scan(/#{search_string}/).count == 1 }
        .to become_true_within(10.seconds)
    end
  end

  context '#out#qflist' do
    let(:out) { 'qflist' }

    xit 'aborts on bufdelete' do
      press ":call esearch#init({'cwd': '/dev/urandom'})<Enter>#{search_string}<Enter>"
      wait_quickfix_enter

      expect { `ps aux`.include?(search_string) }
        .to become_true_within(10.seconds)

      # From :help bdelete
      #   Unload buffer [N] (default: current buffer) and delete it from the buffer list.
      press ':bdelete<Enter>'

      expect { !`ps aux`.include?(search_string) }
        .to become_true_within(10.seconds)
    end

    xit 'aborts on search restart' do
      2.times do
        press ":call esearch#init({'cwd': '/dev/urandom'})<Enter>#{search_string}<Enter>"
        wait_quickfix_enter
      end

      expect { ps_aux_without_sh_delegate_command.scan(/#{search_string}/).count == 1 }
        .to become_true_within(10.seconds)
    end
  end

  include_context 'dumpable'
end
