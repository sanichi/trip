class CreateTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :trips do |t|
      t.string     :title, limit: 50
      t.date       :start_date
      t.date       :end_date
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
