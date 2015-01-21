class CreateUsersTable < ActiveRecord::Migration
  def change
    create_table :users do |t|
    	t.string :email
    	t.string :password
    	t.string :password_confirmation
    	t.binary :password_digest
    	t.float :distance_travelled
    	t.string :secret_key
    end
  end
end
