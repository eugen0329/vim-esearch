#!/usr/bin/env rake

task :ci => [:dump, :test]

task :dump do
  sh 'vim --version'
end

task :test do
  cmd = 'rspec spec'
  puts "Starting to run #{cmd}..."
  sh "bundle exec #{cmd}"
  raise "#{cmd} failed!" unless $?.exitstatus == 0
end
