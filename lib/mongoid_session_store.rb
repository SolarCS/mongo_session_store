require 'securerandom'
$:.unshift File.dirname(__FILE__)

require 'mongoid_session_store/store'

module MongoidSessionStore
  autoload :VERSION, 'mongoid_session_store/version'

  def self.collection_name=(name)
    @collection_name = name

    MongoidSessionStore::Session.store_in collection: name

    @collection_name
  end

  def self.collection_name
    @collection_name
  end

  # Internal: Default collection name for all the stores.
  self.collection_name = 'sessions'
end

