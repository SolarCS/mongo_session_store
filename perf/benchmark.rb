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

  large_session =  {
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
    'rack.session'               => large_session,
    'rack.session.options'       => { :id => store.send(:generate_sid) }
  }
  benchmark "session save" do
    id = store.send(:generate_sid)
    ids << id
    store.send(:set_session, env.merge({'rack.session.options' => { :id => id }}), id, env['rack.session'])
    # store.send(:commit_session, env.merge({'rack.session.options' => { :id => ids.last }}), 200, {}, [])
  end

  ids.shuffle!

  env = {
    'rack.request.cookie_string' => "",
    'HTTP_COOKIE'                => "",
    'rack.request.cookie_hash'   => { '_session_id' => MongoidSessionStore::Session.last._id }
  }
  benchmark "session load" do
    id = ids.pop
    local_env = env.merge({'rack.request.cookie_hash'   => { '_session_id' => id }})
    # store.send(:prepare_session, local_env)
    sid, data = store.send(:get_session, local_env, id)
    # something = local_env['rack.session']["something"] # trigger the load
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
