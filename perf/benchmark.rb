require 'benchmark'
require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'action_dispatch'
require 'pry'
require File.expand_path('../../lib/mongoid_session_store', __FILE__)

# Set the database that the spec suite connects to.
Mongoid.configure do |config|
  config.load_configuration(
    clients: {
      default: {
        database: 'test_session_stores',
        hosts: [ '127.0.0.1:27017' ],
        options: {
          max_pool_size: 1,
        }
      }
    },
  )
end

RUNS = 2000
SESSION_OPTIONS_KEY = MongoidStore::SESSION_OPTIONS_KEY
SESSION_RECORD_KEY = MongoidStore::SESSION_RECORD_KEY

def benchmark(test_name, &block)
  time = Benchmark.realtime do
    RUNS.times do
      yield
    end
  end
  puts "#{(time/RUNS*100_000).round / 100.0}ms per #{test_name}"
end

def benchmark_store(store)
  collection = MongoidSessionStore::Session.collection
  collection.delete_many

  large_session = {
    :something => "not nothing",
    :left => "not right",
    :welcome => "not despised",
    :visits => [
      "http://www.google.com",
      "localhost:3000",
      "http://localhost:3000/increment_session",
      "http://www.iso.org/iso/country_codes/iso_3166_code_lists/iso-3166-1_decoding_table.htm",
      "http://www.geonames.org/search.html?q=2303+australia&country="
    ],
    :one_k_of_data => "a"*1024,
    :another_k => "b"*1024,
    :more_data => [5]*500,
    :too_much_data_for_a_cookie => "c"*8000,
    :a_bunch_of_floats_in_embedded_docs => [{:float_a => 3.141, :float_b => -1.1}]*100
  }

  ids = []

  env = {
    SESSION_RECORD_KEY => large_session,
    SESSION_OPTIONS_KEY => { :id => store.send(:generate_sid) }
  }
  benchmark "session save" do
    id = store.send(:generate_sid)
    ids << id
    request = ActionDispatch::Request.new(env.merge(SESSION_OPTIONS_KEY => { id: id }))
    store.send(:write_session, request, id, env[SESSION_RECORD_KEY], {})
  end

  ids.shuffle!

  env = {
    Rack::RACK_REQUEST_COOKIE_STRING => '',
    Rack::HTTP_COOKIE                => '',
    SESSION_RECORD_KEY => large_session,
    SESSION_OPTIONS_KEY => { :id => store.send(:generate_sid) }
  }
  benchmark "session load" do
    id = ids.pop
    request = ActionDispatch::Request.new(env.merge({ Rack::RACK_REQUEST_COOKIE_HASH => { 'session_id' => id } }))
    sid, data = store.send(:find_session, request, id)
    raise data.inspect unless data[:something] == "not nothing" && data[:a_bunch_of_floats_in_embedded_docs][0] == {:float_a => 3.141, :float_b => -1.1}
  end

  stats = MongoidSessionStore::Session.stats
  puts "           Total Size: #{stats['size']}"
  puts "         Object count: #{stats['count']}"
  puts "  Average object size: #{stats['avgObjSize']}"
  puts "          Index sizes: #{stats['indexSizes'].inspect}"
end

puts "MongoidStore..."
benchmark_store(MongoidSessionStore::Store.new(nil))
