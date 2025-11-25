class Day < ApplicationRecord
  include Remarkable

  MAX_TITLE = 50

  belongs_to :trip, inverse_of: :days

  before_validation :normalize_attributes

  validates :date, presence: true
  validates :date, uniqueness: { scope: :trip_id }
  validates :title, presence: true, length: { maximum: MAX_TITLE }
  validate :date_within_trip_range

  default_scope { order(date: :asc) }

  def html(guest: true)
    to_html(notes, guest: guest)
  end

  def sequence
    return nil unless trip && date
    (date - trip.start_date).to_i + 1
  end

  private

  def normalize_attributes
    title&.squish!
  end

  def date_within_trip_range
    return if date.blank? || trip.blank?
    unless date.between?(trip.start_date, trip.end_date)
      errors.add(:date, "must be within trip dates (#{trip.start_date} to #{trip.end_date})")
    end
  end
end
