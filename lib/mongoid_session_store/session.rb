require 'mongoid'

module MongoidSessionStore
  class Session
    include Mongoid::Document
    include Mongoid::Timestamps

    field :data, type: BSON::Binary, default: -> { Session.binary_data({}) }

    def self.binary_data(data)
      BSON::Binary.new(Marshal.dump(data), :generic)
    end

    def self.stats
      collection.client.command(collstats: storage_options[:collection]).first
    end
  end
end
