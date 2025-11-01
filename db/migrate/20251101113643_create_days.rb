class CreateDays < ActiveRecord::Migration[8.1]
  def change
    create_table :days do |t|
      t.references :trip, null: false, foreign_key: true
      t.date :date, null: false
      t.string :title, limit: 50
      t.boolean :draft, default: true
      t.text :notes

      t.timestamps
    end

    add_index :days, [:trip_id, :date], unique: true
  end
end
