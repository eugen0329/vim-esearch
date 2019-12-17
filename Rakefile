#!/usr/bin/env rake

RSPEC_COMMAND = "bundle exec rspec --color --order rand --format doc --fail-fast=3"

task ci_system: [:print_versions, :system]
task ci_vim8: [:print_versions, :vim8]
task ci_vimproc: [:print_versions, :vimproc]


task :print_versions do
  sh 'vim --version'
  sh 'ag --version'
  sh 'ack --version'
  sh 'rg --version'
  sh 'pt --version'
end

task :system do
  sh "#{RSPEC_COMMAND} ./spec/plugin/backend/system_spec.rb"
  raise "RSPEC_COMMAND failed!" unless $?.exitstatus == 0
end

task :vim8 do
  sh "#{RSPEC_COMMAND} ./spec/plugin/backend/vim8_spec.rb"
  raise "RSPEC_COMMAND failed!" unless $?.exitstatus == 0
end

task :vimproc do
  sh "#{RSPEC_COMMAND} ./spec/plugin/backend/vim8_spec.rb"
  raise "RSPEC_COMMAND failed!" unless $?.exitstatus == 0
end
