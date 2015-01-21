class CreateLobbies < ActiveRecord::Migration
  def change
    create_table :lobbies do |t|
      t.string :name
      t.integer :limit
      t.string :password
      t.boolean :racing
      t.string :map
      t.string :host

      t.timestamps
    end
    add_index :lobbies, :name, unique: true
  end
end
