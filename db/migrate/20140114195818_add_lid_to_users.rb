class AddLidToUsers < ActiveRecord::Migration
  def change
    add_column :users, :lid, :integer
  end
end
