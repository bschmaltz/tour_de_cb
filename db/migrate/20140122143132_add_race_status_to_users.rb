class AddRaceStatusToUsers < ActiveRecord::Migration
  def change
    add_column :users, :race_status, :string
  end
end
