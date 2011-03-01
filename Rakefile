require "bundler"
Bundler::GemHelper.install_tasks

require "rspec/core/rake_task"

begin
  require "hanna/rdoctask"
rescue LoadError
  require "rake/rdoctask"
end

task :default => :spec

Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "doc"
  rdoc.title = "Flags Column"
  rdoc.main = "README.rdoc"

  rdoc.options << "--line-numbers" << "--inline-source"
  rdoc.options << "--charset" << "utf-8"

  rdoc.rdoc_files.include "README.rdoc", "CHANGELOG.rdoc", "MIT-LICENSE"
  rdoc.rdoc_files.include "lib/**/*.rb"
  rdoc.rdoc_files.exclude "lib/flags_column/version.rb"
end

namespace :rdoc do
  desc "Show the HTML documentation in Firefox"
  task :show do
    sh "firefox doc/index.html"
  end
end

desc "Run all specs"
RSpec::Core::RakeTask.new("spec") do |t|
  t.pattern = FileList["spec/**/*_spec.rb"]
end

