class AddOtpToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :otp_required, :boolean, default: false
    add_column :users, :otp_secret, :string, limit: 32
    add_column :users, :last_otp_at, :integer
  end
end
