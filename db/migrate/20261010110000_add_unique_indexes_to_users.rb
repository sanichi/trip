class AddUniqueIndexesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
    add_index :users, :name, unique: true
  end
end
