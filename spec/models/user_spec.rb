require "rails_helper"

RSpec.describe User do
  describe "normalization" do
    it "downcases and squishes the email" do
      user = build(:user, email: "  TrIp@sAnichie.me ")
      user.valid?
      expect(user.email).to eq "trip@sanichie.me"
    end

    it "squishes the name without changing its case" do
      user = build(:user, name: "  Mark   Orr ")
      user.valid?
      expect(user.name).to eq "Mark Orr"
    end
  end

  describe "email uniqueness" do
    it "is case insensitive" do
      create(:user, email: "trip@sanichie.me")
      expect(build(:user, email: "TrIp@sAnichie.me")).not_to be_valid
    end
  end
end
