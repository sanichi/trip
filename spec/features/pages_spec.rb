require 'rails_helper'

describe PagesController, js: true do
  let(:admin) { create(:user, admin: true) }
  let(:user)  { create(:user, admin: false) }

  context "admin" do
    before(:each) do
      login admin
    end

    context "home" do
      it "show" do
        expect(page).to have_title t("note.notes")
      end
    end

    context "env" do
      it "show" do
        click_link t("user.admin")
        click_link t("pages.env.title")
        expect(page).to have_title t("pages.env.title")
      end
    end

    context "help" do
      it "show" do
        click_link t("pages.help.title")
        expect(page).to have_title t("pages.help.title")
      end
    end
  end

  context "user" do
    before(:each) do
      login user
    end

    context "home" do
      it "show" do
        expect(page).to have_title t("note.notes")
      end
    end

    context "env" do
      it "show" do
        expect(page).to_not have_css "a", text: t("user.admin")
        expect(page).to_not have_css "a", text: t("pages.env.title")

        visit env_path
        expect_forbidden page
      end
    end

    context "help" do
      it "show" do
        click_link t("pages.help.title")
        expect(page).to have_title t("pages.help.title")
      end
    end
  end

  context "guest" do
    before(:each) do
      visit home_path
    end

    context "home" do
      it "show" do
        expect(page).to have_title t("pages.home.title")
      end
    end

    context "env" do
      it "show" do
        expect(page).to_not have_css "a", text: t("user.admin")
        expect(page).to_not have_css "a", text: t("pages.env.title")

        visit env_path
        expect_forbidden page
      end
    end

    context "help" do
      it "show" do
        expect(page).to_not have_css "a", text: t("pages.help.title")

        visit help_path
        expect_forbidden page
      end
    end
  end
end
