require 'rails_helper'

describe Trip, js: true do
  let(:admin) { create(:user, admin: true) }
  let(:user)  { create(:user, admin: false) }
  let(:data)  { build(:trip) }
  let!(:trip) { create(:trip, user: admin) }

  context "admins" do
    before(:each) do
      login(admin)
      click_link t("trip.trips")
    end

    context "create" do
      it "success" do
        click_link t("trip.new")
        fill_in t("trip.title"), with: data.title
        fill_in t("trip.start_date"), with: data.start_date
        fill_in t("trip.end_date"), with: data.end_date
        click_button t("save")

        expect(page).to have_title data.title
        expect(Trip.count).to eq 2
        tr = Trip.first
        expect(tr.title).to eq data.title
        expect(tr.start_date).to eq data.start_date
        expect(tr.end_date).to eq data.end_date
        expect(tr.user).to eq admin
      end

      it "failure" do
        click_link t("trip.new")
        fill_in t("trip.start_date"), with: data.start_date
        click_button t("save")

        expect(page).to have_title t("trip.new")
        expect(Trip.count).to eq 1
        expect_error(page, "blank")
      end
    end

    context "edit" do
      it "title" do
        click_link trip.title
        click_link t("edit")

        expect(page).to have_title t("trip.edit")

        fill_in t("trip.title"), with: data.title
        click_button t("save")

        expect(page).to have_title data.title
        expect(Trip.count).to eq 1
        tr = Trip.find(trip.id)
        expect(tr.title).to eq data.title
      end

      it "dates" do
        click_link trip.title
        click_link t("edit")

        expect(page).to have_title t("trip.edit")

        fill_in t("trip.start_date"), with: data.start_date
        fill_in t("trip.end_date"), with: data.end_date
        click_button t("save")

        expect(page).to have_title trip.title
        expect(Trip.count).to eq 1
        tr = Trip.find(trip.id)
        expect(tr.start_date).to eq data.start_date
        expect(tr.end_date).to eq data.end_date
      end
    end
  end

  context "users" do
    let!(:user_trip) { create(:trip, user: user) }

    before(:each) do
      login(user)
      click_link t("trip.trips")
    end

    it "view" do
      click_link trip.title
      expect(page).to have_title trip.title
    end

    it "create" do
      click_link t("trip.new")
      fill_in t("trip.title"), with: data.title
      fill_in t("trip.start_date"), with: data.start_date
      fill_in t("trip.end_date"), with: data.end_date
      click_button t("save")

      expect(page).to have_title data.title
      expect(Trip.count).to eq 3
      tr = Trip.first
      expect(tr.title).to eq data.title
      expect(tr.start_date).to eq data.start_date
      expect(tr.end_date).to eq data.end_date
      expect(tr.user).to eq user
    end

    it "edit own trip" do
      click_link user_trip.title
      click_link t("edit")

      expect(page).to have_title t("trip.edit")

      fill_in t("trip.title"), with: data.title
      click_button t("save")

      expect(page).to have_title data.title
      tr = Trip.find(user_trip.id)
      expect(tr.title).to eq data.title
    end

    it "can't edit other users' trips" do
      visit edit_trip_path(trip)
      expect_forbidden(page)
    end
  end

  context "guests" do
    before(:each) do
      visit root_path
    end

    it "view" do
      expect(page).to have_css "a", text: t("trip.trips")
      click_link t("trip.trips")
      expect(page).to have_title t("trip.trips")
      click_link trip.title
      expect(page).to have_title trip.title
    end

    it "create" do
      visit new_trip_path
      expect_forbidden page
    end

    it "edit" do
      visit edit_trip_path(trip)
      expect_forbidden(page)
    end
  end
end
