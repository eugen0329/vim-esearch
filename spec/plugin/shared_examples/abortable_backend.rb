# frozen_string_literal: true

RSpec.shared_examples 'an abortable backend' do |backend|
  include Helpers::RunningProcesses
  include Helpers::ReportEditorStateOnError

  let(:adapter) { 'ag' }
  let(:out) { 'win' }
  let(:empty_cwd_for_infinite_search) { '' }
  # We will identify our command using UUID search_string (generated as a static
  # string intetionally)
  let(:search_string) do
    "550e8400-e29b-41d4-a716-446655440000#{Configuration.test_env_number}"
  end
  let(:command_pattern) { search_string }
  # sh script spawns a main search process, so we have to ignore it to avoid
  # working with two process (parent and child)
  let(:infinity_search_executable) { 'search_in_infinite_random_stdin.sh' }
  let(:ignore_pattern) { infinity_search_executable }

  around(:all) do |e|
    esearch.configure(backend: backend, adapter: adapter, out: out, root_markers: [], paths: '', live_update: 0)
    esearch.configuration.adapter_bin =
      "sh #{Configuration.scripts_dir}/#{infinity_search_executable} #{adapter}"
    esearch.configuration.submit!
    e.run
    esearch.configuration.adapter_bin = adapter
    editor.cleanup!
  end

  around do |e|
    expect(esearch).to have_no_process_matching(search_string) # prevent false positive results
    e.run
    esearch.close_search!
    esearch.grep_and_kill_process_by!(search_string)
    expect(esearch).to have_no_process_matching(search_string)
  end

  include_context 'report editor state on error'

  shared_examples 'abort on actions' do
    it 'aborts on bufdelete' do
      esearch.search!(search_string, cwd: empty_cwd_for_infinite_search)

      expect(esearch)
        .to  have_search_started
        .and have_running_processes_matching(command_pattern, ignore_pattern, count: 1)
        .and have_search_freezed

      editor.bufdelete!
      expect(esearch).to have_no_process_matching(search_string)
    end

    it 'aborts on search restart' do
      esearch.search!(search_string, cwd: empty_cwd_for_infinite_search)
      # `#have_search_freezed` must be called first to prevent possible race
      # condition errors
      expect(esearch)
        .to  have_search_started
        .and have_search_freezed
        .and have_running_processes_matching(command_pattern, ignore_pattern, count: 1)

      KnownIssues.mark_example_pending_if_known_issue(self) do
        # Duplication instead of 2.times {} as it's cannot be said what time a fail
        # has happened
        esearch.search!(search_string, cwd: empty_cwd_for_infinite_search)
        expect(esearch)
          .to  have_search_started
          .and have_search_freezed
          .and have_running_processes_matching(command_pattern, ignore_pattern, count: 1)
      end
    end
  end

  context '#out#win', :abortion do
    let(:out) { 'win' }

    include_examples 'abort on actions'
  end

  context '#out#qflist', :abortion do
    let(:out) { 'qflist' }

    include_examples 'abort on actions'
  end
end
