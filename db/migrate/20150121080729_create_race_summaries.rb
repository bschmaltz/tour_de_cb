class CreateRaceSummaries < ActiveRecord::Migration
  def change
    create_table :race_summaries do |t|
      t.integer :uid
      t.integer :rid
      t.integer :place
      t.float :time
      t.float :distance
      t.float :calories
      t.string :map

      t.timestamps
    end
  end
end
