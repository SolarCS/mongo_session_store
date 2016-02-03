require 'rails_helper'

describe Devise::SessionsController, type: :request do
  def create_user
    post_data = {
       'user[email]'                 => 'person@example.com',
       'user[password]'              => 'secret',
       'user[password_confirmation]' => 'secret'
    }
    post '/users', post_data
  end

  def login
    post_data = {
       'user[email]'                 => 'person@example.com',
       'user[password]'              => 'secret',
       'user[password_confirmation]' => 'secret'
    }
    post '/users/sign_in', post_data
  end

  def logout
    delete '/users/sign_out'
  end

  def i_should_be_logged_in
    expect(controller.user_signed_in?).to eq true
    get '/'
    expect(response.body.squish).to match /You are logged in as person@example.com/
  end

  def i_should_not_be_logged_in
    expect(controller.user_signed_in?).to eq false
    get '/'
    expect(response.body.squish).to match /You are logged out/
  end

  it "does not explode" do
  end

  it "allows user creation" do
    expect(User.count).to eq 0
    create_user
    expect(response.status).to eq 302
    get response.redirect_url
    expect(User.count).to eq 1
    expect(response.body.squish).to match /You are logged in as person@example.com/
    expect(response.body.squish).to match /You have signed up successfully/
  end

  it "allows user logout" do
    create_user
    i_should_be_logged_in
    logout
    expect(response.status).to eq 302
    i_should_not_be_logged_in
    expect(response.body.squish).to match /Signed out successfully/
  end

  it "allows user login" do
    create_user
    logout
    i_should_not_be_logged_in
    login
    expect(response.status).to eq 302
    i_should_be_logged_in
    expect(response.body.squish).to match /Signed in successfully/
  end

  it "stores the session in the sessions collection" do
    collection = db["sessions"]
    expect(collection.find.count).to eq 0
    create_user
    expect(collection.find.count).to eq 1
  end

  it "allows renaming of the collection that stores the sessions" do
    collection = db["dance_parties"]
    expect(collection.find.count).to eq 0
    MongoidSessionStore.collection_name = "dance_parties"
    create_user
    expect(collection.find.count).to eq 1
  end
end
