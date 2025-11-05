class RenameImageDateTakenToTaken < ActiveRecord::Migration[8.1]
  def change
    rename_column :images, :date_taken, :taken
  end
end
