class CreateRaces < ActiveRecord::Migration
  def change
    create_table :races do |t|
      t.integer :lid
      t.integer :rid
      t.datetime :end_time

      t.timestamps
    end
  end
end
