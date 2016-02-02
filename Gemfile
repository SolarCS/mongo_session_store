source 'https://rubygems.org'

gemspec name: 'mongoid_session_store'

group :development, :test do
  gem 'devise'
  gem 'rake'

  gem 'pry'

  gem 'test-unit'
  gem 'rspec-rails'

  if RUBY_PLATFORM == 'java'
    gem 'jdbc-sqlite3'
    gem 'activerecord-jdbc-adapter'
    gem 'activerecord-jdbcsqlite3-adapter'
    gem 'jruby-openssl'
    gem 'jruby-rack'
  else
    gem 'sqlite3' # for devise User storage
  end

  case ENV['RAILS_VERS']
  when '4.2'
    gem 'rails', '~>4.2.0'
  else
    gem 'rails'
  end

  case ENV['MONGOID_SESSION_STORE_ORM']
  when 'mongoid'
    gem 'mongoid', '>= 5.0.0'
  else
    gem 'mongoid'
  end
end
