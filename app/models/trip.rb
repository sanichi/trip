class Trip < ApplicationRecord
  MAX_TITLE = 50
  MAX_DAYS = 90

  belongs_to :user, inverse_of: :trips

  before_validation :normalize_attributes

  validates :title, presence: true, length: { maximum: MAX_TITLE }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_not_before_start_date
  validate :trip_duration_not_too_long

  default_scope { order(created_at: :desc) }

  private

  def normalize_attributes
    title&.squish!
  end

  def end_date_not_before_start_date
    return if start_date.blank? || end_date.blank?
    if end_date < start_date
      errors.add(:end_date, "cannot be before start date")
    end
  end

  def trip_duration_not_too_long
    return if start_date.blank? || end_date.blank?
    duration = (end_date - start_date).to_i
    if duration > MAX_DAYS
      errors.add(:end_date, "trip cannot be longer than #{MAX_DAYS} days")
    end
  end
end
