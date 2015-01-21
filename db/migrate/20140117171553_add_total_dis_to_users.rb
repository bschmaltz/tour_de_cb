class AddTotalDisToUsers < ActiveRecord::Migration
  def change
    add_column :users, :total_dis, :float
  end
end
