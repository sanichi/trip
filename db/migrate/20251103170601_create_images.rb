class CreateImages < ActiveRecord::Migration[8.1]
  def change
    create_table :images do |t|
      t.string :caption, limit: 250, null: false
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.datetime :date_taken
      t.bigint :user_id, null: false
      t.timestamps
    end

    add_index :images, :user_id
    add_foreign_key :images, :users
  end
end
