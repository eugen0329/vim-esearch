# frozen_string_literal: true

require 'spec_helper'

describe 'esearch#pattern' do
  include Helpers::FileSystem
  include VimlValue::SerializationHelpers
  include Helpers::Pattern::ConvertFromVim

  describe 'esearch#pattern#vim2literal#convert' do
    context 'when filename contains special characters' do
      subject(:convert) do
        lambda do |input|
          editor.echo(func('esearch#pattern#vim2literal#convert', input))
        end
      end

      include_examples 'avoid conversion when slashes are escaped'
      include_examples 'sanitize match modes atoms'
      include_examples 'sanitize position atoms'

      it { expect(convert.call('\\_^')).to eq('')    }
      it { expect(convert.call('\\_$')).to eq('')    }
      it { expect(convert.call('\\>')).to  eq('')    }
      it { expect(convert.call('\\<')).to  eq('')    }
      it { expect(convert.call('\\%^')).to eq('')    }
      it { expect(convert.call('\\%$')).to eq('')    }

      it { expect(convert.call('\\^')).to  eq('\\^') }
      it { expect(convert.call('\\$')).to  eq('\\$') }
      it { expect(convert.call('\\/')).to  eq('/') }

      context 'when preceding slashes are escaped except one' do
        it { expect(convert.call('\\\\\\_^')).to eq('\\\\') }
        it { expect(convert.call('\\\\\\_$')).to eq('\\\\') }
        it { expect(convert.call('\\\\\\>')).to  eq('\\\\')  }
        it { expect(convert.call('\\\\\\<')).to  eq('\\\\')  }
        it { expect(convert.call('\\\\\\%^')).to eq('\\\\') }
        it { expect(convert.call('\\\\\\%$')).to eq('\\\\') }
        it { expect(convert.call('\\\\\\/')).to  eq('\\\\/') }
      end
    end
  end
end
