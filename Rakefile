#!/usr/bin/env rake

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
  sh "bundle exec rspec ./spec/plugin/backend/system_spec.rb"
  raise "Command failed!" unless $?.exitstatus == 0
end

task :vim8 do
  sh "bundle exec rspec ./spec/plugin/backend/vim8_spec.rb"
  raise "Command failed!" unless $?.exitstatus == 0
end

task :vimproc do
  sh "bundle exec rspec ./spec/plugin/backend/vim8_spec.rb"
  raise "Command failed!" unless $?.exitstatus == 0
end
