require 'action_dispatch/middleware/session/abstract_store'
require 'mongoid_session_store/session'

module MongoidSessionStore
  class Store < ActionDispatch::Session::AbstractStore
    # The class used for session storage. Defaults to MongoidSessionStore::Session
    cattr_accessor :session_class
    self.session_class = MongoidSessionStore::Session

    SESSION_RECORD_KEY = 'rack.session.record'
    SESSION_OPTIONS_KEY = Rack::RACK_SESSION_OPTIONS

  private

    # Rack: If nil is provided as the session id, generation of a new valid id
    # should occur within.
    #
    # Returns [session_id, session].
    def find_session(request, sid)
      record = get_session_record(request, sid)
      record.session_id = generate_sid if record.new_record?
      [record.session_id, record.data]
    end

    # Rack: Returns the session id if the session was saved successfully, or
    # false if the session could not be saved.
    def write_session(request, sid, session_data, options)
      session = get_session_record(request, sid)
      session.data = session_data
      session.save ? session.session_id : false
    end

    # Rack: Returns a new session id or nil if options[:drop].
    def delete_session(request, _sid, options)
      old_record = destroy_session(request)
      return if options[:drop]

      generate_sid.tap do |new_sid|
        if options[:renew]
          request.env[SESSION_RECORD_KEY] =
            @@session_class.create(session_id: new_sid, data: old_record&.data)
        end
      end
    end

    # Internal: Deletes the record for the current session and removes it from
    # the request env.
    #
    # Returns the old record, if one existed.
    def destroy_session(request)
      @@session_class.find_by_session_id(current_session_id(request)).tap do |record|
        request.env[SESSION_RECORD_KEY] = nil
        record&.destroy
      end
    end

    # Internal: Finds the record for the current session (or initializes a
    # record if none exists) and sets it in the request env.
    def get_session_record(request, sid)
      model = @@session_class.find_by_session_id(sid) ||
        @@session_class.new(session_id: sid || generate_sid)

      if request.env[SESSION_OPTIONS_KEY][:id].nil?
        request.env[SESSION_RECORD_KEY] = model
      else
        request.env[SESSION_RECORD_KEY] ||= model
      end

      model
    end
  end
end

module ActionDispatch
  module Session
    MongoidStore = MongoidSessionStore::Store
  end
end

MongoidStore = MongoidSessionStore::Store
