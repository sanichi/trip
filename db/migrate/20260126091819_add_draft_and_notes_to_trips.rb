class AddDraftAndNotesToTrips < ActiveRecord::Migration[8.1]
  def change
    add_column :trips, :draft, :boolean, default: true
    add_column :trips, :notes, :text
  end
end
