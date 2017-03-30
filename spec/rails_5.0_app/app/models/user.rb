class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # Database Authenticatable
  field :email, type: String
  field :encrypted_password, type: String, default: ''

  devise :database_authenticatable, :registerable
end
