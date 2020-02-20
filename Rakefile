# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'parallel_tests/tasks'

task default: %i[generate_lexer generate_parser rspec]

task generate_lexer:  'spec/support/lib/viml_value/lexer.rb'
task generate_parser: 'spec/support/lib/viml_value/parser.rb'

RSpec::Core::RakeTask.new(:rspec) do |t|
  t.rspec_opts = ENV['RSPEC_OPTS']
end

rule '.rb' => '.rl' do |t|
  sh "ragel -e -L -F0 -R -o #{t.name} #{t.source}"
end

rule '.rb' => '.y' do |t|
  sh "racc --output-file=#{t.name} #{t.source}"
end
