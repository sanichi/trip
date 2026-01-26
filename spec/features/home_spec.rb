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

    it "shows blank page when trip is draft even with ready days" do
      trip = create(:trip, user: admin, draft: true)
      create(:day, trip: trip, draft: false, date: trip.start_date)

      visit root_path

      expect(page).not_to have_css(".trip-selector")
      expect(page).not_to have_css(".day-navigator")
    end
  end

  context "one ready trip" do
    let!(:trip) { create(:trip, :ready, user: admin, title: "Japan 2025") }
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
    let!(:trip1) { create(:trip, :ready, user: admin, title: "Japan 2025", start_date: Date.new(2025, 5, 1), end_date: Date.new(2025, 5, 10)) }
    let!(:trip2) { create(:trip, :ready, user: admin, title: "Italy 2024", start_date: Date.new(2024, 6, 1), end_date: Date.new(2024, 6, 10)) }
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
    let!(:trip) { create(:trip, :ready, user: admin, start_date: Date.new(2025, 5, 1), end_date: Date.new(2025, 5, 20)) }

    it "shows navigator with intro and one day" do
      create(:day, trip: trip, draft: false, date: Date.new(2025, 5, 1))

      visit root_path

      expect(page).to have_css(".day-navigator")
      expect(page).to have_link(t("trip.intro"))
    end

    it "shows next/previous arrows with 2 days for affordance" do
      create(:day, trip: trip, draft: false, date: Date.new(2025, 5, 1))
      create(:day, trip: trip, draft: false, date: Date.new(2025, 5, 2))

      visit root_path

      # Next/previous arrows provide navigation affordance
      expect(page).to have_content(t("symbol.previous"))
      expect(page).to have_content(t("symbol.next"))
      # First/last arrows not needed when all items visible (intro + 2 days = 3 items)
      expect(page).not_to have_content(t("symbol.first"))
      expect(page).not_to have_content(t("symbol.last"))
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

    it "shows next/previous but hides first/last arrows when 5 or fewer items" do
      (1..4).each do |i|
        create(:day, trip: trip, draft: false, date: Date.new(2025, 5, i))
      end

      visit root_path

      # 4 days + intro = 5 items, all fit in window
      expect(page).to have_content(t("symbol.previous"))
      expect(page).to have_content(t("symbol.next"))
      expect(page).not_to have_content(t("symbol.first"))
      expect(page).not_to have_content(t("symbol.last"))
    end

    it "shows all four arrow types when more than 5 items" do
      (1..6).each do |i|
        create(:day, trip: trip, draft: false, date: Date.new(2025, 5, i))
      end

      visit root_path

      # 6 days + intro = 7 items
      expect(page).to have_content(t("symbol.first"))
      expect(page).to have_content(t("symbol.previous"))
      expect(page).to have_content(t("symbol.next"))
      expect(page).to have_content(t("symbol.last"))
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

  context "intro" do
    let!(:trip) { create(:trip, :ready, user: admin, notes: "Welcome to our trip!") }

    it "shows intro as first navigator item when trip has days" do
      create(:day, trip: trip, draft: false, date: trip.start_date, title: "Day One")

      visit root_path

      expect(page).to have_css(".day-navigator")
      expect(page).to have_link(t("trip.intro"))
      expect(page).to have_css(".current-day", text: "Day 1")
    end

    it "shows intro content when selected" do
      create(:day, trip: trip, draft: false, date: trip.start_date)

      visit root_path(intro: true, trip: trip.id)

      expect(page).to have_css(".current-day", text: t("trip.intro"))
      expect(page).to have_content("Welcome to our trip!")
      expect(page).not_to have_css(".day-date")
    end

    it "shows only intro when trip has no ready days" do
      visit root_path

      expect(page).not_to have_css(".day-navigator")
      expect(page).to have_content("Welcome to our trip!")
    end

    it "shows Introduction heading when on intro even without notes" do
      trip.update!(notes: nil)

      visit root_path

      expect(page).to have_css(".day-title h3", text: t("trip.introduction"))
    end

    it "remembers intro selection in session" do
      create(:day, trip: trip, draft: false, date: trip.start_date)

      visit root_path(intro: true, trip: trip.id)
      visit root_path

      expect(page).to have_css(".current-day", text: t("trip.intro"))
    end

    it "navigates from intro to first day" do
      create(:day, trip: trip, draft: false, date: trip.start_date, notes: "First day content")

      visit root_path(intro: true, trip: trip.id)
      click_link t("symbol.next")

      expect(page).to have_content("First day content")
    end

    it "navigates from first day back to intro" do
      day = create(:day, trip: trip, draft: false, date: trip.start_date)

      visit root_path(day: day.id)
      click_link t("symbol.previous")

      expect(page).to have_content("Welcome to our trip!")
    end
  end

  context "admin link" do
    let!(:trip) { create(:trip, :ready, user: admin) }
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
