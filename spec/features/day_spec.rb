require 'rails_helper'

describe Day, js: true do
  let(:admin) { create(:user, admin: true) }
  let!(:trip) { create(:trip, user: admin, start_date: Date.today, end_date: Date.today + 4) }
  let(:data)  { build(:day, trip: trip) }
  let!(:day)  { create(:day, trip: trip, date: trip.start_date, draft: false) }

  context "admins" do
    let(:next_day) { trip.start_date + 1 }

    before(:each) do
      login(admin)
      click_link t("trip.trips")
      click_link trip.title
    end

    context "create" do
      it "success" do
        click_link t("day.new")
        fill_in t("day.date"), with: next_day
        fill_in t("day.title"), with: data.title
        fill_in t("day.notes"), with: data.notes
        click_button t("save")

        expect(page).to have_title data.title
        expect(Day.count).to eq 2
        d = Day.find_by(date: next_day)
        expect(d.title).to eq data.title
        expect(d.date).to eq next_day
        expect(d.notes).to eq data.notes
        expect(d.draft).to eq true
        expect(d.trip).to eq trip
      end

      it "failure" do
        click_link t("day.new")
        fill_in t("day.date"), with: next_day
        fill_in t("day.notes"), with: data.notes
        click_button t("save")

        expect(page).to have_title t("day.new")
        expect(Day.count).to eq 1
        expect_error(page, "blank")
      end

      it "defaults to first available slot" do
        click_link t("day.new")
        expect(page).to have_field(t("day.date"), with: next_day.to_s)
      end

      it "redirects when no slots available" do
        # Fill all remaining slots
        (trip.start_date + 1..trip.end_date).each do |date|
          create(:day, trip: trip, date: date)
        end

        visit new_trip_day_path(trip)
        expect(page).to have_title trip.title
        expect(page).to have_content "No available date slots left for this trip"
      end
    end

    context "edit" do
      it "title" do
        click_link day.day_label
        click_link t("edit")

        expect(page).to have_title t("day.edit")

        fill_in t("day.title"), with: data.title
        click_button t("save")

        expect(page).to have_title data.title
        expect(Day.count).to eq 1
        d = Day.find(day.id)
        expect(d.title).to eq data.title
      end

      it "draft" do
        click_link day.day_label
        click_link t("edit")

        expect(page).to have_title t("day.edit")

        check t("day.draft")
        click_button t("save")

        expect(page).to have_title day.title
        expect(Day.count).to eq 1
        d = Day.find(day.id)
        expect(d.draft).to eq true
      end
    end

    context "date validations" do
      it "cannot create day outside trip date range" do
        click_link t("day.new")
        fill_in t("day.date"), with: trip.end_date + 1
        fill_in t("day.title"), with: data.title
        click_button t("save")

        expect(page).to have_title t("day.new")
        expect(Day.count).to eq 1
        expect_error(page, "must be within trip dates")
      end

      it "cannot change trip dates to orphan existing days" do
        click_link t("edit")

        expect(page).to have_title t("trip.edit")

        fill_in t("trip.end_date"), with: trip.start_date - 1
        click_button t("save")

        expect(page).to have_title t("trip.edit")
        expect_error(page, "cannot change dates")
        expect_error(page, "would be outside trip range")
      end

      it "can change trip dates when days remain valid" do
        click_link t("edit")

        expect(page).to have_title t("trip.edit")

        fill_in t("trip.end_date"), with: trip.end_date + 5
        click_button t("save")

        expect(page).to have_title trip.title
        tr = Trip.find(trip.id)
        expect(tr.end_date).to eq trip.end_date + 5
      end
    end
  end

  context "users" do
    let(:user)       { create(:user, admin: false) }
    let!(:user_trip) { create(:trip, user: user, start_date: Date.today, end_date: Date.today + 4) }
    let(:next_day)   { user_trip.start_date + 1 }
    let!(:user_day)  { create(:day, trip: user_trip, date: user_trip.start_date, draft: true) }

    before(:each) do
      login(user)
      click_link t("trip.trips")
    end

    it "view" do
      click_link trip.title
      click_link day.day_label
      expect(page).to have_title day.title
    end

    it "create" do
      click_link user_trip.title
      click_link t("day.new")
      fill_in t("day.date"), with: next_day
      fill_in t("day.title"), with: data.title
      fill_in t("day.notes"), with: data.notes
      click_button t("save")

      expect(page).to have_title data.title
      expect(Day.count).to eq 3
      d = Day.find_by(date: next_day)
      expect(d.title).to eq data.title
      expect(d.date).to eq next_day
      expect(d.notes).to eq data.notes
      expect(d.draft).to eq true
      expect(d.trip).to eq user_trip
    end

    it "edit own day" do
      click_link user_trip.title
      click_link user_day.day_label
      click_link t("edit")

      expect(page).to have_title t("day.edit")

      fill_in t("day.title"), with: data.title
      click_button t("save")

      expect(page).to have_title data.title
      d = Day.find(user_day.id)
      expect(d.title).to eq data.title
    end

    it "can't edit other users' days" do
      visit edit_trip_day_path(trip, day)
      expect_forbidden(page)
    end
  end

  context "guests" do
    before(:each) do
      visit root_path
    end

    it "view" do
      visit trip_path(trip)
      expect(page).to have_title trip.title
      click_link day.day_label
      expect(page).to have_title day.title
    end

    it "create" do
      visit new_trip_day_path(trip)
      expect_forbidden page
    end

    it "edit" do
      visit edit_trip_day_path(trip, day)
      expect_forbidden(page)
    end
  end
end
