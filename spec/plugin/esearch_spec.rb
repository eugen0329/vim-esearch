require 'spec_helper'

context 'esearch' do
  it 'can be tested' do
    expect(has('clientserver')).to be_truthy
    meet_requirements = has('nvim') || bool_expr('esearch#util#has_vimproc()')
    expect(meet_requirements).to be_truthy
  end
end
