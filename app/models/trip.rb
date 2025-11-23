class Trip < ApplicationRecord
  MAX_TITLE = 50
  MAX_DAYS = 90

  belongs_to :user, inverse_of: :trips
  has_many :days, inverse_of: :trip, dependent: :destroy

  scope :ready, -> { joins(:days).where(days: { draft: false }).distinct }

  before_validation :normalize_attributes

  validates :title, presence: true, length: { maximum: MAX_TITLE }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_not_before_start_date
  validate :trip_duration_not_too_long
  validate :date_changes_dont_invalidate_days

  default_scope { order(created_at: :desc) }

  def ready?
    days.exists?(draft: false)
  end

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

  def date_changes_dont_invalidate_days
    return if start_date.blank? || end_date.blank?
    return unless start_date_changed? || end_date_changed?

    days.each do |day|
      unless day.date.between?(start_date, end_date)
        errors.add(:base, "cannot change dates: Day #{day.sequence} (#{day.date}) would be outside trip range")
      end
    end
  end
end
