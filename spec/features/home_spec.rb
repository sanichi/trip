require 'rails_helper'

describe "Home", js: true do
  let(:admin) { create(:user, admin: true) }

  context "no ready trips" do
    it "shows blank page with sign in link" do
      visit root_path

      expect(page).not_to have_css(".trip-selector")
      expect(page).not_to have_css(".day-navigator")
      expect(page).not_to have_css(".day-content")
      expect(page).to have_link(t("session.sign_in"))
    end

    it "shows blank page when trips exist but all days are drafts" do
      trip = create(:trip, user: admin)
      create(:day, trip: trip, draft: true, date: trip.start_date)

      visit root_path

      expect(page).not_to have_css(".trip-selector")
      expect(page).not_to have_css(".day-navigator")
    end
  end

  context "one ready trip" do
    let!(:trip) { create(:trip, user: admin, title: "Japan 2025") }
    let!(:day1) { create(:day, trip: trip, draft: false, date: trip.start_date, title: "Arrival", notes: "Landed in Tokyo") }

    it "shows trip title without dropdown" do
      visit root_path

      expect(page).to have_css(".trip-selector h2", text: "Japan 2025")
      expect(page).not_to have_css(".dropdown")
    end

    it "shows day content" do
      visit root_path

      expect(page).to have_css(".day-content", text: "Landed in Tokyo")
    end
  end

  context "multiple ready trips" do
    let!(:trip1) { create(:trip, user: admin, title: "Japan 2025", start_date: Date.new(2025, 5, 1), end_date: Date.new(2025, 5, 10)) }
    let!(:trip2) { create(:trip, user: admin, title: "Italy 2024", start_date: Date.new(2024, 6, 1), end_date: Date.new(2024, 6, 10)) }
    let!(:day1) { create(:day, trip: trip1, draft: false, date: trip1.start_date) }
    let!(:day2) { create(:day, trip: trip2, draft: false, date: trip2.start_date) }

    it "shows dropdown to select trips" do
      visit root_path

      expect(page).to have_css(".dropdown")
      expect(page).to have_button(trip1.title)
    end

    it "can switch between trips" do
      visit root_path

      click_button trip1.title
      click_link trip2.title

      expect(page).to have_button(trip2.title)
    end
  end

  context "day navigator" do
    let!(:trip) { create(:trip, user: admin, start_date: Date.new(2025, 5, 1), end_date: Date.new(2025, 5, 20)) }

    it "hides navigator when only one ready day" do
      create(:day, trip: trip, draft: false, date: Date.new(2025, 5, 1))

      visit root_path

      expect(page).not_to have_css(".day-navigator")
    end

    it "shows only non-draft days" do
      create(:day, trip: trip, draft: false, date: Date.new(2025, 5, 1), title: "Day One")
      create(:day, trip: trip, draft: true, date: Date.new(2025, 5, 2), title: "Draft Day")
      day3 = create(:day, trip: trip, draft: false, date: Date.new(2025, 5, 3), title: "Day Three")

      visit root_path

      # Day 1 is current (shown as date, not link), Day 3 is a link
      # Day 2 (draft) should not appear at all
      expect(page).to have_link(class: "day-link", href: root_path(day: day3.id))
      # Both responsive forms are present in DOM (short form hidden on desktop, long form hidden on mobile)
      expect(page).to have_selector(".day-link span.d-md-none", text: "D3", visible: :all)
      expect(page).to have_selector(".day-link span.d-none.d-md-inline", text: "Day 3", visible: :all)
      # Day 2 should not appear in any form
      expect(page).not_to have_text(/D2|Day 2/)
    end

    it "hides arrows when 5 or fewer days" do
      (1..5).each do |i|
        create(:day, trip: trip, draft: false, date: Date.new(2025, 5, i))
      end

      visit root_path

      expect(page).not_to have_css(".nav-arrow")
    end

    it "shows arrows when more than 5 days" do
      (1..7).each do |i|
        create(:day, trip: trip, draft: false, date: Date.new(2025, 5, i))
      end

      visit root_path

      expect(page).to have_css(".nav-arrow")
    end

    it "clicking day link changes content" do
      day1 = create(:day, trip: trip, draft: false, date: Date.new(2025, 5, 1), notes: "First day content")
      day2 = create(:day, trip: trip, draft: false, date: Date.new(2025, 5, 2), notes: "Second day content")

      visit root_path

      expect(page).to have_content("First day content")

      find("a.day-link[href='#{root_path(day: day2.id)}']").click

      expect(page).to have_content("Second day content")
    end
  end

  context "admin link" do
    let!(:trip) { create(:trip, user: admin) }
    let!(:day) { create(:day, trip: trip, draft: false, date: trip.start_date) }

    it "guest sees sign in link" do
      visit root_path

      expect(page).to have_link(t("session.sign_in"))
      expect(page).not_to have_link(t("user.admin"))
    end

    it "logged in user sees admin link" do
      login(admin)
      visit root_path

      expect(page).to have_link(t("user.admin"))
      expect(page).not_to have_link(t("session.sign_in"))
    end

    it "admin link returns to trips index" do
      login(admin)
      click_link t("trip.trips")
      visit root_path
      click_link t("user.admin")

      expect(page).to have_title(t("trip.trips"))
    end
  end
end
