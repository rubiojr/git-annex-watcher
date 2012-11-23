require 'rubygems'
require 'rake'
require './lib/gaw/version.rb'
require 'jeweler'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.version = GAW::VERSION
  gem.name = "git-annex-watcher"
  gem.homepage = "http://github.com/rubiojr/git-annex-watcher"
  gem.license = "MIT"
  gem.summary = %Q{Git Annex Desktop Status Icon}
  gem.description = %Q{Git Annex Desktop Status Icon}
  gem.email = "rubiojr@frameos.org"
  gem.authors = ["Sergio Rubio"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_runtime_dependency 'rb-inotify'
  gem.add_runtime_dependency 'uuidtools'
  gem.add_runtime_dependency 'gtk2'
end
Jeweler::RubygemsDotOrgTasks.new

task :default => :build

task :dist, :destdir do |t,args|
  destdir = (args[:destdir] || '/tmp')
  pwd = Dir.pwd
  Dir.chdir '../'
  system "tar --exclude git-annex-watcher/exclude --exclude " + \
         "git-annex-watcher/debian " + \
         "-czf #{destdir}/git-annex-watcher_#{GAW::VERSION}.orig.tar.gz " + \
         "git-annex-watcher"
  Dir.chdir pwd
end

task :deb, :destdir do |t, args|
  destdir = (args[:destdir] || '/tmp')
  pwd = Dir.pwd
  Dir.chdir '../'
  system "tar --exclude git-annex-watcher/exclude --exclude " + \
         "git-annex-watcher/debian " + \
         "-czf #{destdir}/git-annex-watcher_#{GAW::VERSION}.orig.tar.gz " + \
         "git-annex-watcher"
  Dir.chdir "#{destdir}"
  system "tar xzf git-annex-watcher_#{GAW::VERSION}.orig.tar.gz"
  Dir.chdir pwd
  system "cp -r debian #{destdir}/git-annex-watcher/"
end
