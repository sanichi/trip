class AddLengthLimitsToUsers < ActiveRecord::Migration[8.1]
  def up
    change_column :users, :name, :string, limit: 30
    change_column :users, :email, :string, limit: 50
  end

  def down
    change_column :users, :name, :string, limit: nil
    change_column :users, :email, :string, limit: nil
  end
end
