require 'rails_helper'

describe ActionDispatch::Session::MongoidStore do
  SESSION_OPTIONS_KEY = ActionDispatch::Session::MongoidStore::SESSION_OPTIONS_KEY
  SESSION_RECORD_KEY = ActionDispatch::Session::MongoidStore::SESSION_RECORD_KEY

  let(:app) { nil }
  let(:store) { ActionDispatch::Session::MongoidStore.new(app) }
  let(:request) { ActionDispatch::Request.new(SESSION_OPTIONS_KEY => {}) }

  def request_record
    request.env[SESSION_RECORD_KEY]
  end

  let(:sid) { SecureRandom.hex }
  let(:old_sid) { SecureRandom.hex }
  let(:data) {{
    something: 'not nothing',
    left: 'not right',
    welcome: 'not despised',
    visits: [
      'http://www.google.com',
      'localhost:3000',
      'http://localhost:3000/increment_session',
      'http://www.iso.org/iso/country_codes/iso_3166_code_lists/iso-3166-1_decoding_table.htm',
      'http://www.geonames.org/search.html?q=2303+australia&country=',
    ],
    one_k_of_data: 'a'*1024,
    another_k: 'b'*1024,
    more_data: [5]*500,
    too_much_data_for_a_cookie: 'c'*8000,
    a_bunch_of_floats_in_embedded_docs: [
      { float_a: 3.141, float_b: -1.1 }
    ] * 100,
  }}

  describe '#find_session' do
    before do
      allow(MongoidStore.session_class).to receive(:where).and_return([])
    end

    it 'generates a new session id if given a nil session id' do
      sid, session_data = store.send(:find_session, request, nil)

      expect(sid).not_to eq nil
      expect(session_data).to eq({})
      expect(request_record.class).to eq MongoidStore.session_class
      expect(request_record.session_id).to eq sid
    end

    it 'generates a new session id if session is not found' do
      sid, session_data = store.send(:find_session, request, old_sid)

      expect(sid).not_to eq old_sid
      expect(session_data).to eq({})
      expect(request_record.class).to eq MongoidStore.session_class
      expect(request_record.session_id).to eq sid
    end
  end

  describe '#write_session' do
    it 'returns the session id if the session was saved' do
      result = store.send(:write_session, request, sid, data, {})

      expect(result).to eq sid
      expect(request_record.class).to eq MongoidStore.session_class
      expect(request_record.session_id).to eq sid
      expect(request_record.data).to eq data
      expect(MongoidStore.session_class.find_by_session_id(sid).data).to eq data
    end

    it 'returns false if the session could not be saved' do
      allow_any_instance_of(MongoidStore.session_class).to receive(:save).and_return(false)

      result = store.send(:write_session, request, sid, data, {})

      expect(result).to be false
    end
  end

  describe '#delete_session' do
    before do
      request.set_header Rack::RACK_SESSION, OpenStruct.new(id: sid)
    end

    context 'the session exists' do
      before do
        throw(:abort) unless store.send(:write_session, request, sid, data, {})
      end

      it 'deletes the session' do
        result = store.send(:delete_session, request, sid, drop: true)

        expect(result).to eq nil
        expect(request_record).to eq nil
        expect(MongoidStore.session_class.find_by_session_id(sid)).to eq nil
      end

      it 'deletes the session and returns a new sid' do
        result = store.send(:delete_session, request, sid, {})

        expect(result).not_to eq nil
        expect(result).not_to eq sid
        expect(request_record).to eq nil
        expect(MongoidStore.session_class.find_by_session_id(sid)).to eq nil
      end

      it 'returns a new sid and creates a new session with the old data if :renew is true' do
        result = store.send(:delete_session, request, sid, renew: true)
        new_session = MongoidStore.session_class.find_by_session_id(result)

        expect(new_session).not_to eq nil
        expect(new_session.session_id).not_to eq sid
        expect(new_session.data).to eq data
        expect(request_record).to eq new_session
      end
    end

    context 'the session does not exist' do
      it 'does not return a new sid' do
        result = store.send(:delete_session, request, sid, drop: true)

        expect(result).to eq nil
        expect(request_record).to eq nil
      end

      it 'return a new sid' do
        result = store.send(:delete_session, request, sid, {})

        expect(result).not_to eq nil
        expect(result).not_to eq sid
        expect(request_record).to eq nil
      end

      it 'returns a new sid and creates a new session if :renew is true' do
        result = store.send(:delete_session, request, sid, renew: true)
        new_session = MongoidStore.session_class.find_by_session_id(result)

        expect(new_session).not_to eq nil
        expect(new_session.session_id).not_to eq sid
        expect(request_record).to eq new_session
      end
    end
  end
end
