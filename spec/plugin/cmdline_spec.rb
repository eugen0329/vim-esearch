require 'spec_helper'

context 'esearch' do
  describe '#cmdline' do

    it 'has working help' do
      help_output = press_output('call esearch#init()<Enter><C-o><C-h><CR>')
      expect(help_output).not_to match(/Error/), 'expected not to receive any errors'
    end
  end
end
