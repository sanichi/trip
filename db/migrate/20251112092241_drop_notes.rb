class DropNotes < ActiveRecord::Migration[8.1]
  def change
    drop_table :notes
  end
end
