# frozen_string_literal: true

require 'rspec/core/rake_task'

task default: %i[generate_lexer rspec]

task generate_lexer: 'spec/support/lib/viml_value/lexer.rb'
RSpec::Core::RakeTask.new(:rspec)

rule '.rb' => '.rl' do |t|
  sh "ragel -e -L -F0 -R -o #{t.name} #{t.source}"
end
