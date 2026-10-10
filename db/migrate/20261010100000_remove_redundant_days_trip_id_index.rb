class RemoveRedundantDaysTripIdIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :days, :trip_id, name: "index_days_on_trip_id"
  end
end
