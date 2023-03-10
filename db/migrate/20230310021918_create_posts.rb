class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.references :user, foreign_key: true
      t.string :provider, null: false, default: "twitter"
      t.string :provider_id
      t.string :body
      t.string :posted_at
      t.text :provider_post_raw

      t.timestamps
    end

    add_index :posts, [:provider, :provider_id], unique: true
  end
end
