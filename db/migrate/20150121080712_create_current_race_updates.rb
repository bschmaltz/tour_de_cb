class CreateCurrentRaceUpdates < ActiveRecord::Migration
  def change
    create_table :current_race_updates do |t|
      t.integer :uid
      t.integer :rid
      t.float :distance
      t.float :game_time
      t.float :speed

      t.timestamps
    end
  end
end
