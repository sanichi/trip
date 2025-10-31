require 'rails_helper'

RSpec.describe TripHelper, type: :helper do
  describe '#trip_duration' do
    context 'when year is in the title' do
      it 'omits year for same month trip' do
        trip = build(:trip, title: "Europe 2025", start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 1, 7))
        expect(helper.trip_duration(trip)).to eq("January 1-7")
      end

      it 'omits year for different month trip' do
        trip = build(:trip, title: "Summer 2025", start_date: Date.new(2025, 7, 26), end_date: Date.new(2025, 8, 7))
        expect(helper.trip_duration(trip)).to eq("Jul 26 - Aug 7")
      end

      it 'omits year when year matches end day' do
        trip = build(:trip, title: "Japan 2026", start_date: Date.new(2026, 5, 6), end_date: Date.new(2026, 5, 26))
        expect(helper.trip_duration(trip)).to eq("May 6-26")
      end
    end

    context 'when year is not in the title' do
      it 'includes year once at end for same month trip' do
        trip = build(:trip, title: "Beach Vacation", start_date: Date.new(2025, 1, 15), end_date: Date.new(2025, 1, 20))
        expect(helper.trip_duration(trip)).to eq("January 15-20, 2025")
      end

      it 'includes year once at end for different month trip' do
        trip = build(:trip, title: "Summer Trip", start_date: Date.new(2025, 7, 26), end_date: Date.new(2025, 8, 7))
        expect(helper.trip_duration(trip)).to eq("Jul 26 - Aug 7, 2025")
      end
    end

    context 'same month trips' do
      it 'formats with full month name and day range' do
        trip = build(:trip, title: "Spring Break", start_date: Date.new(2025, 2, 6), end_date: Date.new(2025, 2, 26))
        expect(helper.trip_duration(trip)).to eq("February 6-26, 2025")
      end
    end

    context 'different month trips' do
      it 'formats with abbreviated months and spaces around dash' do
        trip = build(:trip, title: "Christmas 2024", start_date: Date.new(2024, 12, 26), end_date: Date.new(2025, 1, 3))
        expect(helper.trip_duration(trip)).to eq("Dec 26 - Jan 3")
      end
    end

    context 'same month and year check' do
      it 'checks same month and same year together' do
        trip = build(:trip, title: "Trip", start_date: Date.new(2026, 5, 6), end_date: Date.new(2026, 5, 26))
        expect(helper.trip_duration(trip)).to eq("May 6-26, 2026")
      end
    end
  end
end
