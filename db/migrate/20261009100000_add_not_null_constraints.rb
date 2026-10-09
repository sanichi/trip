class AddNotNullConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :days, :title, false
    change_column_null :trips, :title, false
    change_column_null :trips, :start_date, false
    change_column_null :trips, :end_date, false
    change_column_null :users, :name, false
  end
end
