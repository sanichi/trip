require 'rails_helper'

RSpec.describe DayHelper, type: :helper do
  let(:trip) { create(:trip, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 10)) }

  describe '#day_previous' do
    context 'with only one day' do
      it 'returns nil' do
        day = create(:day, trip: trip, date: Date.new(2026, 5, 1))
        expect(helper.day_previous(day)).to be_nil
      end
    end

    context 'with two days' do
      let!(:day1) { create(:day, trip: trip, date: Date.new(2026, 5, 1)) }
      let!(:day2) { create(:day, trip: trip, date: Date.new(2026, 5, 2)) }

      it 'returns the other day when viewing first day' do
        expect(helper.day_previous(day1)).to eq(day2)
      end

      it 'returns the other day when viewing second day' do
        expect(helper.day_previous(day2)).to eq(day1)
      end
    end

    context 'with three or more days' do
      let!(:day1) { create(:day, trip: trip, date: Date.new(2026, 5, 1)) }
      let!(:day2) { create(:day, trip: trip, date: Date.new(2026, 5, 3)) }
      let!(:day3) { create(:day, trip: trip, date: Date.new(2026, 5, 5)) }

      it 'wraps to last day when viewing first day' do
        expect(helper.day_previous(day1)).to eq(day3)
      end

      it 'returns previous day when viewing middle day' do
        expect(helper.day_previous(day2)).to eq(day1)
      end

      it 'returns previous day when viewing last day' do
        expect(helper.day_previous(day3)).to eq(day2)
      end
    end
  end

  describe '#day_next' do
    context 'with only one day' do
      it 'returns nil' do
        day = create(:day, trip: trip, date: Date.new(2026, 5, 1))
        expect(helper.day_next(day)).to be_nil
      end
    end

    context 'with two days' do
      let!(:day1) { create(:day, trip: trip, date: Date.new(2026, 5, 1)) }
      let!(:day2) { create(:day, trip: trip, date: Date.new(2026, 5, 2)) }

      it 'returns the other day when viewing first day' do
        expect(helper.day_next(day1)).to eq(day2)
      end

      it 'returns the other day when viewing second day' do
        expect(helper.day_next(day2)).to eq(day1)
      end
    end

    context 'with three or more days' do
      let!(:day1) { create(:day, trip: trip, date: Date.new(2026, 5, 1)) }
      let!(:day2) { create(:day, trip: trip, date: Date.new(2026, 5, 3)) }
      let!(:day3) { create(:day, trip: trip, date: Date.new(2026, 5, 5)) }

      it 'returns next day when viewing first day' do
        expect(helper.day_next(day1)).to eq(day2)
      end

      it 'returns next day when viewing middle day' do
        expect(helper.day_next(day2)).to eq(day3)
      end

      it 'wraps to first day when viewing last day' do
        expect(helper.day_next(day3)).to eq(day1)
      end
    end
  end
end
