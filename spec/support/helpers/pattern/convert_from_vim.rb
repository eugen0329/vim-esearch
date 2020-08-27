# frozen_string_literal: true

module Helpers::Pattern::ConvertFromVim
  extend RSpec::Matchers::DSL

  shared_examples 'avoid conversion when slashes are escaped' do
    it { expect(convert.call('\\\\_^')).to eq('\\\\_^') }
    it { expect(convert.call('\\\\_$')).to eq('\\\\_$') }
    it { expect(convert.call('\\\\>')).to  eq('\\\\>')  }
    it { expect(convert.call('\\\\<')).to  eq('\\\\<')  }
    it { expect(convert.call('\\\\zs')).to eq('\\\\zs') }
    it { expect(convert.call('\\\\ze')).to eq('\\\\ze') }
    it { expect(convert.call('\\\\%^')).to eq('\\\\%^') }
    it { expect(convert.call('\\\\%$')).to eq('\\\\%$') }
  end

  shared_examples 'sanitize match modes atoms' do
    it { expect(convert.call('\m')).to eq('') }
    it { expect(convert.call('\M')).to eq('') }
    it { expect(convert.call('\v')).to eq('') }
    it { expect(convert.call('\V')).to eq('') }
    it { expect(convert.call('\c')).to eq('') }
    it { expect(convert.call('\C')).to eq('') }
  end

  shared_examples 'sanitize position atoms' do
    it { expect(convert.call('\\zs')).to     eq('')    }
    it { expect(convert.call('\\ze')).to     eq('')    }
    it { expect(convert.call('\\%V')).to     eq('')    }
    it { expect(convert.call('\\%#')).to     eq('')    }
    it { expect(convert.call("\\%<'a")).to   eq('')    }
    it { expect(convert.call("\\%'k")).to    eq('')    }
    it { expect(convert.call("\\%>'z")).to   eq('')    }
    it { expect(convert.call('\\%<1l')).to   eq('')    }
    it { expect(convert.call('\\%20l')).to   eq('')    }
    it { expect(convert.call('\\%>300l')).to eq('')    }
    it { expect(convert.call('\\%<1c')).to   eq('')    }
    it { expect(convert.call('\\%20c')).to   eq('')    }
    it { expect(convert.call('\\%>300c')).to eq('')    }
    it { expect(convert.call('\\%<1v')).to   eq('')    }
    it { expect(convert.call('\\%20v')).to   eq('')    }
    it { expect(convert.call('\\%>300v')).to eq('')    }
  end
end
