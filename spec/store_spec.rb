require 'spec_helper'
require 'securerandom'
require 'ostruct'
require 'mongoid_session_store/store'

describe ActionDispatch::Session::MongoidStore do
  SESSION_OPTIONS_KEY = ActionDispatch::Session::MongoidStore::SESSION_OPTIONS_KEY
  SESSION_RECORD_KEY  = ActionDispatch::Session::MongoidStore::SESSION_RECORD_KEY

  before do
    @app   = nil
    @store = ActionDispatch::Session::MongoidStore.new(@app)
    @env   = {}
  end

  describe "#get_session" do
    let(:old_sid) { SecureRandom.hex }

    before do
      allow(MongoidSessionStore::Session).to receive(:where).and_return([])
    end

    it "generates a new session id if given a nil session id" do
      sid, session_data = @store.send(:get_session, @env, nil)

      expect(sid).not_to eq nil
      expect(session_data).to eq({})
      expect(@env[SESSION_RECORD_KEY].class).to eq MongoidSessionStore::Session
      expect(@env[SESSION_RECORD_KEY]._id).to eq sid
    end

    it "generates a new session id if session is not found" do
      sid, session_data = @store.send(:get_session, @env, old_sid)

      expect(sid).not_to eq old_sid
      expect(session_data).to eq({})
      expect(@env[SESSION_RECORD_KEY].class).to eq MongoidSessionStore::Session
      expect(@env[SESSION_RECORD_KEY]._id).to eq sid
    end
  end
end
