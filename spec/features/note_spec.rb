require 'rails_helper'

describe Note, js: true do
  let(:admin) { create(:user, admin: true) }
  let(:user)  { create(:user, admin: false) }
  let(:data)  { build(:note) }
  let!(:note) { create(:note, user: admin, draft: false) }

  context "admins" do
    before(:each) do
      login(admin)
      click_link t("note.notes")
    end

    context "create" do
      it "success" do
        click_link t("note.new")
        fill_in t("note.title"), with: data.title
        fill_in t("note.markdown"), with: data.markdown
        click_button t("save")

        expect(page).to have_title data.title
        expect(Note.count).to eq 2
        n = Note.first
        expect(n.title).to eq data.title
        expect(n.markdown).to eq data.markdown
        expect(n.draft).to eq true
        expect(n.user).to eq admin
      end

      it "failure" do
        click_link t("note.new")
        fill_in t("note.markdown"), with: data.markdown
        click_button t("save")

        expect(page).to have_title t("note.new")
        expect(Note.count).to eq 1
        expect_error(page, "blank")
      end
    end

    context "edit" do
      it "title" do
        click_link note.title
        click_link t("edit")

        expect(page).to have_title t("note.edit")

        fill_in t("note.title"), with: data.title
        click_button t("save")

        expect(page).to have_title data.title
        expect(Note.count).to eq 1
        n = Note.find(note.id)
        expect(n.title).to eq data.title
      end

      it "draft" do
        click_link note.title
        click_link t("edit")

        expect(page).to have_title t("note.edit")

        uncheck t("note.draft")
        click_button t("save")

        expect(page).to have_title note.title
        expect(Note.count).to eq 1
        n = Note.find(note.id)
        expect(n.draft).to eq false
      end
    end
  end

  context "users" do
    before(:each) do
      login(user)
      click_link t("note.notes")
    end

    it "view" do
      click_link note.title
      expect(page).to have_title note.title
    end

    it "create" do
      expect(page).to_not have_css "a", text: t("note.new")
      visit new_note_path
      expect_forbidden page
    end

    it "edit" do
      visit edit_note_path(note)
      expect_forbidden(page)
    end
  end

  context "guests" do
    before(:each) do
      visit root_path
    end

    it "view" do
      expect(page).to_not have_css "a", text: t("note.notes")
      visit note_path(note)
      expect_forbidden page
    end

    it "create" do
      visit new_note_path
      expect_forbidden page
    end

    it "edit" do
      visit edit_note_path(note)
      expect_forbidden(page)
    end
  end
end
