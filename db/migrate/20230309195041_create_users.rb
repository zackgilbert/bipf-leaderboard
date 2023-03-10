class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name, null: false, default: ""
      t.string :avatar_url
      t.string :twitter_id
      t.string :twitter_username
      t.string :twitter_access_token
      t.string :twitter_token_secret
      t.datetime :twitter_last_synced_at
      t.text :twitter_last_error
      t.text :twitter_profile_raw

      t.timestamps
    end

    add_index :users, :name, unique: true
  end
end
