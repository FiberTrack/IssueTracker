class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
  :recoverable,  :validatable,
  # for Google OmniAuth
  :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :activities
  has_many :issue_watchers

  before_validation :generate_api_key, on: :create
  validates :api_key, presence: true
  after_initialize :set_defaults

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.full_name = auth.info.name # assuming the user model has a name
      user.avatar_url = auth.info.image # assuming the user model has an image
    end
  end

  def set_defaults
    self.bio ||= "Not Assigned"
  end

  def generate_api_key
    self.api_key ||= SecureRandom.uuid
  end

end