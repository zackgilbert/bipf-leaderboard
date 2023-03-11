class UpdateUsersWithLinkedin < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.string :linkedin_id
      t.string :linkedin_username
      t.string :linkedin_access_token
      t.datetime :linkedin_last_synced_at
      t.text :linkedin_last_error
      t.text :linkedin_profile_raw
    end

    add_index :users, [:twitter_id]
    add_index :users, [:twitter_username]
    add_index :users, [:linkedin_id]
    add_index :users, [:linkedin_username]
  end
end
