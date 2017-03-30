require 'rubygems'
require 'rake'
require 'bundler'
Bundler::GemHelper.install_tasks name: 'mongoid_session_store'

def run_with_output(command)
  puts "Running: #{command}"
  system(command)
end

def set_versions(rails_version)
  success = true
  unless File.exists?("Gemfile_Rails_#{rails_version}_mongoid_#{RUBY_VERSION}.lock")
    success &&= run_with_output("export RAILS_VERS=#{rails_version}; bundle update")
    success &&= run_with_output("cp Gemfile.lock Gemfile_Rails_#{rails_version}_mongoid_#{RUBY_VERSION}.lock")
  else
    success &&= run_with_output("rm Gemfile.lock")
    success &&= run_with_output("cp Gemfile_Rails_#{rails_version}_mongoid_#{RUBY_VERSION}.lock Gemfile.lock")
  end
  success
end

@rails_versions = ['5.0']

task :default => :test_all

desc 'Test each session store against Rails'
task :test_all do
  # Wait for mongod to start on Travis.
  # From the Mongo Ruby Driver gem.
  if ENV['TRAVIS']
    require 'mongo'
    client = Mongo::Client.new(['127.0.0.1:27017'])
    begin
      puts "Waiting for MongoDB..."
      client.command(Mongo::Server::Monitor::STATUS)
    rescue Mongo::ServerSelector::NoServerAvailable => e
      sleep(2)
      # 1 Retry
      puts "Waiting for MongoDB..."
      client.cluster.scan!
      client.command(Mongo::ServerSelector::NoServerAvailable)
    end
  end

  @failed_suites = []

  @rails_versions.each do |rails_version|
    success = set_versions(rails_version)

    unless success && run_with_output("export RAILS_VERS=#{rails_version}; bundle exec rspec spec")
      @failed_suites << "Rails #{rails_version} / mongoid"
    end
  end

  if @failed_suites.any?
    puts "\033[0;31mFailed:"
    puts @failed_suites.join("\n")
    print "\033[0m"
    exit(1)
  else
    print "\033[0;32mAll passed! Success! "
    "Yahoooo!!!".chars.each { |c| sleep 0.4; print c; STDOUT.flush }
    puts "\033[0m"
  end
end

@rails_versions.each do |rails_version|
  desc "Set Gemfile.lock to #{rails_version} with mongoid"
  task :"use_#{rails_version.gsub('.', '')}_mongoid" do
    set_versions(rails_version)
  end

  desc "Test against #{rails_version} with mongoid"
  task :"test_#{rails_version.gsub('.', '')}_mongoid" do
    set_versions(rails_version)
    success = run_with_output("export RAILS_VERS=#{rails_version}; bundle exec rspec spec")
    exit(1) unless success
  end

  desc "Rebundle for #{rails_version} with mongoid"
  task :"rebundle_#{rails_version.gsub('.', '')}_mongoid" do
    run_with_output "rm Gemfile_Rails_#{rails_version}_mongoid_#{RUBY_VERSION}.lock Gemfile.lock"
    set_versions(rails_version)
  end
end
