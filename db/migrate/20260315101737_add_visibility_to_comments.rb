class AddVisibilityToComments < ActiveRecord::Migration[7.2]
  def change
    add_column :comments, :visibility, :string, default: 'public', null: false
    add_index :comments, :visibility
  end
end
