require 'rails_helper'

describe Image, js: true do
  let(:admin) { create(:user, admin: true) }
  let(:user)  { create(:user, admin: false) }
  let(:data)  { build(:image) }
  let!(:image) { create(:image, user: admin) }

  context "admins" do
    before(:each) do
      login(admin)
      click_link t("image.images")
    end

    it "view images index" do
      expect(page).to have_title t("image.images")
      expect(page).to have_content image.caption
    end

    it "view image" do
      visit image_path(image)
      expect(page).to have_title "#{t('image.image')} #{image.id}"
      expect(page).to have_content image.caption
      expect(page).to have_css "img"
    end
  end

  context "users" do
    let!(:user_image) { create(:image, user: user) }

    before(:each) do
      login(user)
      click_link t("image.images")
    end

    it "can view all images" do
      expect(page).to have_content image.caption
      expect(page).to have_content user_image.caption
    end

    it "can view image details" do
      visit image_path(user_image)
      expect(page).to have_title "#{t('image.image')} #{user_image.id}"
      expect(page).to have_content user_image.caption
    end

    it "can't edit other users' images" do
      visit edit_image_path(image)
      expect_forbidden(page)
    end
  end

  context "guests" do
    before(:each) do
      visit root_path
    end

    it "cannot see images link" do
      expect(page).to_not have_css "a", text: t("image.images")
    end

    it "cannot view images index" do
      visit images_path
      expect_forbidden page
    end

    it "cannot view image" do
      visit image_path(image)
      expect_forbidden page
    end

    it "cannot create images" do
      visit new_image_path
      expect_forbidden page
    end

    it "cannot edit images" do
      visit edit_image_path(image)
      expect_forbidden(page)
    end
  end
end
