require 'spec_helper'

describe 'esearch' do
  describe '#opts' do
    context '#new' do

      it 'is able to check if within git repository'  do
        expect(expr("system('git rev-parse --is-inside-work-tree >/dev/null 2>&1')"))
          .to be_empty
      end

    end
  end
end
