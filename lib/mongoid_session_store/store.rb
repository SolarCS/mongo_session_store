require 'action_dispatch/middleware/session/abstract_store'
require 'mongoid_session_store/session'

module MongoidSessionStore
  class Store < ActionDispatch::Session::AbstractStore
    SESSION_RECORD_KEY = 'rack.session.record'.freeze
    SESSION_OPTIONS_KEY = Rack::Session::Abstract::ENV_SESSION_OPTIONS_KEY

  private

    def generate_sid
      BSON::ObjectId.new.to_s
    end

    def get_session(env, sid)
      record = find_or_initialize_session(sid)
      env[SESSION_RECORD_KEY] = record
      [record._id, unpack(record.data)]
    end

    def set_session(env, id, session_data, options = {})
      record = get_session_record(env, id)
      # Rack spec dictates that set_session should return true or false
      # depending on whether or not the session was saved or not.
      # However, ActionPack seems to want a session id instead.
      record.update_attributes(id: id, data: pack(session_data)) ? record.id : false
    end

    def find_or_initialize_session(id)
      id && MongoidSessionStore::Session.where(_id: id).first || MongoidSessionStore::Session.new
    end

    def get_session_record(env, id)
      if env[SESSION_OPTIONS_KEY][:id] && env[SESSION_RECORD_KEY]
        env[SESSION_RECORD_KEY]
      else
        env[SESSION_RECORD_KEY] = find_or_initialize_session(id)
      end
    end

    def destroy_session(env, session_id, options)
      destroy(env)
      generate_sid unless options[:drop]
    end

    def destroy(env)
      if sid = current_session_id(env)
        get_session_record(env, sid).destroy
        env[SESSION_RECORD_KEY] = nil
      end
    end

    def pack(data)
      MongoidSessionStore::Session.binary_data(data)
    end

    def unpack(packed)
      return nil unless packed
      Marshal.load(packed.data)
    end
  end
end

module ActionDispatch
  module Session
    MongoidStore = MongoidSessionStore::Store
  end
end
MongoidStore = MongoidSessionStore::Store
