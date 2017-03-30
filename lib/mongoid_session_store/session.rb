require 'mongoid'

module MongoidSessionStore
  class Session
    include Mongoid::Document
    include Mongoid::Timestamps

  # Fields
    # Public: The session id.
    field :_id, as: :session_id, type: String, overwrite: true

    # Public: Session data, stored in binary format.
    field :data, type: BSON::Binary

    # This method is defined in the `protected_attributes` gem.
    if respond_to?(:accessible_attributes)
      attr_accessible :session_id, :data
    end

  # Callbacks
    # Internal: Ensure we store data in binary format.
    before_save :serialize_data

    def self.stats
      collection.client.command(collstats: storage_options[:collection]).first
    end

    def self.find_by_session_id(sid)
      where(session_id: sid).first if sid
    end

    # Internal: Convert session data to binary format.
    def self.to_binary(data)
      BSON::Binary.new(Marshal.dump(data), :generic)
    end

    # Internal: Convert session data from binary format to a Ruby object.
    def self.from_binary(packed)
      Marshal.load(packed.data) if packed
    end

    def initialize(*)
      @data = nil
      super
    end

    # Public: Lazy-unpack the session state that is stored in binary format.
    def data
      @data ||= self.class.from_binary(read_attribute(:data)) || {}
    end

    attr_writer :data

  private

    # Internal: Ensure we convert session data to binary format.
    def serialize_data
      write_attribute(:data, self.class.to_binary(data))
    end
  end
end
