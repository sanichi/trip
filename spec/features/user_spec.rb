require 'rails_helper'

describe User, js: true do
  let!(:admin) { create(:user, admin: true) }
  let!(:user)  { create(:user, admin: false) }
  let!(:otpu)  { create(:user, admin: false, otp_required: true) }
  let(:data)   { build(:user, admin: false) }

  context "admins" do
    before(:each) do
      login admin
      click_link t("user.admin")
      click_link t("user.users")
    end

    it "user counts" do
      expect(page).to have_title t("user.users")
      expect(User.where(admin: true).count).to eq 1
      expect(User.where(admin: false).count).to eq 2
    end

    it "create user" do
      click_link t("user.new")

      fill_in t("user.name"), with: data.name
      fill_in t("user.email"), with: data.email
      fill_in t("user.password"), with: data.password
      send(data.otp_required ? "check" : "uncheck", t("otp.required"))
      click_button t("save")

      expect(page).to have_title data.name
      expect(User.where(admin: false).count).to eq 3
      u = User.find_by(name: data.name)
      expect(u.password).to be_nil
      expect(u.password_digest).to be_present
      expect(u.email).to eq data.email.downcase
      expect(u.admin).to eq false
      expect(u.otp_required).to eq data.otp_required
      expect(u.otp_secret).to be_nil
      expect(u.last_otp_at).to be_nil

      click_link t("session.sign_out")

      expect(page).to have_title t("title")

      click_link t("session.sign_in")
      fill_in t("user.email"), with: data.email
      fill_in t("user.password"), with: data.password
      click_button t("session.sign_in")

      expect(page).to have_title t("note.notes")
    end

    it "create otp user" do
      click_link t("user.new")

      fill_in t("user.name"), with: data.name
      fill_in t("user.email"), with: data.email
      fill_in t("user.password"), with: data.password
      check t("otp.required")
      click_button t("save")

      expect(page).to have_title data.name
      expect(User.where(admin: false).count).to eq 3
      u = User.find_by(name: data.name)
      expect(u.password).to be_nil
      expect(u.password_digest).to be_present
      expect(u.email).to eq data.email.downcase
      expect(u.admin).to eq false
      expect(u.otp_required).to eq true
      expect(u.otp_secret).to be_nil
      expect(u.last_otp_at).to be_nil

      click_link t("session.sign_out")

      expect(page).to have_title t("title")

      click_link t("session.sign_in")
      fill_in t("user.email"), with: data.email
      fill_in t("user.password"), with: data.password
      click_button t("session.sign_in")

      expect(page).to have_title t("otp.new")
      expect(page).to have_css "p#su_code", text: Rails.application.credentials.test.otp[:secret]

      fill_in t("otp.otp"), with: otp_attempt
      click_button t("otp.submit")

      expect(page).to have_title t("note.notes")
    end

    it "edit user" do
      click_link user.email
      click_link t("edit")
      fill_in t("user.name"), with: data.name
      click_button t("save")

      expect(page).to have_title data.name
      expect(User.where(admin: false, name: data.name).count).to eq 1
    end

    it "edit otp user" do
      expect(otpu.otp_required).to eq true
      expect(otpu.otp_secret).to be_present
      expect(otpu.last_otp_at).to be_present

      click_link otpu.email
      click_link t("edit")
      uncheck t("otp.required")
      click_button t("save")

      expect(page).to have_title otpu.name
      otpu.reload
      expect(otpu.otp_required).to eq false
      expect(otpu.otp_secret).to be_nil
      expect(otpu.last_otp_at).to be_nil
    end

    it "delete user" do
      click_link user.email
      click_link t("edit")
      accept_confirm do
        click_link t("delete")
      end

      expect(page).to have_title t("user.users")
      expect(User.where(admin: false).count).to eq 1
      expect(User.where(admin: true).count).to eq 1
    end
  end

  context "users" do
    before(:each) do
      login user
    end

    it "can log out" do
      click_link t("session.sign_out")

      expect(page).to have_title t("title")
    end

    it "can‘t list users" do
      expect(page).to_not have_css "a", text: t("user.admin")
      expect(page).to_not have_css "a", text: t("user.users")

      visit users_path
      expect_forbidden page
    end

    it "can‘t create users" do
      expect(page).to_not have_css "a", text: t("user.new")

      visit new_user_path
      expect_forbidden page
    end
  end

  context "otp users" do
    before(:each) do
      login otpu
    end

    it "can log in" do
      expect(page).to have_title t("otp.challenge")

      fill_in t("otp.otp"), with: otp_attempt
      click_button t("otp.submit")

      expect(page).to have_title t("note.notes")
    end

    it "can‘t use bad otp" do
      expect(page).to have_title t("otp.challenge")

      fill_in t("otp.otp"), with: "123456"
      click_button t("otp.submit")

      expect(page).to have_title t("otp.challenge")
      expect_error(page, t("otp.invalid"))

      fill_in t("otp.otp"), with: otp_attempt
      click_button t("otp.submit")

      expect(page).to have_title t("note.notes")
    end
  end

  context "guests" do
    before(:each) do
      visit root_path
    end

    it "can login" do
      click_link t("session.sign_in")

      expect(page).to have_title t("session.sign_in")
    end

    it "can‘t list users" do
      expect(page).to_not have_css "a", text: t("user.admin")
      expect(page).to_not have_css "a", text: t("user.users")

      visit users_path
      expect_forbidden page
    end

    it "can‘t create users" do
      expect(page).to_not have_css "a", text: t("user.new")

      visit new_user_path
      expect_forbidden page
    end
  end
end
