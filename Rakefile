require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "seed_dump"
    gem.summary = "{Seed Dumper for Rails}"
    gem.description = %Q{Dump (parts) of your database to db/seeds.rb to get a headstart creating a meaningful seeds.rb file}
    gem.email = 'brian@trucentive.com'
    gem.homepage = 'https://github.com/bmo/seed_dump'
    gem.authors = ['Rob Halff', 'Ryan Oblak', 'Brian Moran']
    gem.license = 'MIT'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "seed_dump #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec
