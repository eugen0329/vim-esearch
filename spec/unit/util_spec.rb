# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

describe 'esearch#util' do
  include Helpers::FileSystem

  around { |e| esearch.editor.with_ignore_cache(&e) }

  describe '#parse_help_options' do
    let(:help_file) { file_named_by_content(format(layout, help_output)) }
    let(:result) { esearch.editor.echo("esearch#util#parse_help_options('cat #{help_file}')") }
    let!(:fixture_directory) { directory([help_file], 'parse_help_options').persist! }
    let(:deserialized_result) { YAML.safe_load(result) }
    let(:layout) do
      <<~HELP_LAYOUT
        Usage: grep [OPTION]... PATTERN [FILE]...
        Example: grep -i 'hello world' menu.h main.c

        %s

        {..} 'fgrep' means 'grep -F'. {..}
        -r is given, - otherwise.  If fewer than two FILEs are given, assume -h.
      HELP_LAYOUT
    end

    # Double checks to avoid matching layout
    after do
      is_expected.not_to include('-F', '-h')
      # TODO: do we need to allow options outputted without left padding?
      is_expected.not_to include('-r')
    end

    # NOTE: those ugly space paddings are kept by intent (as copied from actual
    # grep --help)
    context '#keys' do
      subject { deserialized_result.keys }

      context 'when -s{hort} --long' do
        let(:help_output) { '  -E, --extended-regexp     PATTERN is an {..}' }

        it { is_expected .to contain_exactly('-E', '--extended-regexp') }
      end

      context 'when only --long' do
        let(:help_output) { '      --help                display {..}' }

        it { is_expected .to contain_exactly('--help') }
      end

      context 'when only -s{hort}' do
        let(:help_output) { '  -I                        equivalent to --binary-files=wi{..}' }

        it { is_expected.to contain_exactly('-I') }
      end

      context 'when --long=PARAMETER' do
        let(:help_output) { '  -B, --before-context=NUM  print NUM{..}' }

        it { is_expected.to contain_exactly('-B', '--before-context') }
      end

      context 'when --long, {MISSING DESCRIPTION}' do
        let(:help_output) { '      --color[=WHEN],' }

        it { is_expected.to contain_exactly('--color') }
      end

      context 'when --option[=VALUE]', :debina_grep do
        let(:help_output) { '      --colour[=WHEN]       use markers to {..}' }

        it { is_expected.to contain_exactly('--colour') }
      end

      context 'when --option, {MULTILINE DESCRIPTION}' do
        let(:help_output) do
          "       --colour              use markers to highlight the matching strings;\n" \
          "                             WHEN is 'always', 'never', or 'auto'"
        end

        it { is_expected.to contain_exactly('--colour') }
      end
    end
  end
end
