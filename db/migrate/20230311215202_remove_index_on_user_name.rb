class RemoveIndexOnUserName < ActiveRecord::Migration[7.0]
  def change
    remove_index "users", column: [:name], name: "index_users_on_name"
  end
end
