ENV['MONGOID_SESSION_STORE_ORM'] ||= 'mongoid'
ENV['RAILS_ENV'] = 'test'

require 'bundler/setup'
$:.unshift File.dirname(__FILE__)
