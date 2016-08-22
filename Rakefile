# coding: utf-8

require 'bundler/gem_tasks'
require_relative 'lib/pokeman/version'

# Default.
task :default => :help

# Help.
desc 'Help'
task :help do
  system('rake -T')
end

desc 'Makes you a pokeman developer'
task :dev do
  if ENV['GEM_HOME'].nil?
    puts 'Environment variable GEM_HOME is empty, you should be using RVM for ths task to work.'
    exit(1)
  end

  Rake::Task['install'].invoke

  source = File.dirname(File.absolute_path __FILE__)
  target = "#{ENV['GEM_HOME']}/gems/pokeman-#{PokeMan::VERSION}"
  target_bin = "#{ENV['GEM_HOME']}/bin/cmdapi"
  system("rm -f #{target_bin}")
  system("rm -rf #{target}")
  system("ln -s #{source} #{target}")
  system("ln -s #{source}/bin/cmdapi #{target_bin}")

  puts 'You may now start editing and testing files from within this repo.'
end