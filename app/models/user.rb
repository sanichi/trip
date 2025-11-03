class User < ApplicationRecord
  MAX_EMAIL = 50
  MAX_NAME = 30
  MIN_PASSWORD = 8
  OTP_ISSUER = "trip.sanichi.me"

  has_secure_password

  has_many :notes, dependent: :destroy, inverse_of: :user
  has_many :trips, dependent: :destroy, inverse_of: :user
  has_many :images, dependent: :destroy, inverse_of: :user

  before_validation :normalize_attributes
  after_update :reset_otp

  validates :email, format: { with: /\A\S+@\S+\z/ }, length: { maximum: MAX_EMAIL }, uniqueness: { case_sensitive: false }
  validates :name, length: { maximum: MAX_NAME }, presence: true, uniqueness: true
  validates :password, length: { minimum: MIN_PASSWORD }, allow_nil: true

  default_scope { order(:name) }

  def guest?
    false
  end

  private

  def normalize_attributes
    email&.squish!&.downcase
    name&.squish!
  end

  def reset_otp
    if !otp_required
      update_columns(otp_secret: nil, last_otp_at: nil)
    end
  end
end
