class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true, null: false
      t.string :author_name
      t.string :author_role
      t.text :content


      t.timestamps
    end
  end
end
