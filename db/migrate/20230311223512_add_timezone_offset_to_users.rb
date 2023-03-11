class AddTimezoneOffsetToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :timezone_offset, :string
  end
end
