class AddReviewStatusToComments < ActiveRecord::Migration[7.2]
  def change
    add_column :comments, :review_status, :string, default: 'approved'
    add_column :comments, :reviewed_by_id, :integer
    add_column :comments, :reviewed_at, :datetime
    add_index :comments, :review_status
    add_index :comments, :reviewed_by_id
  end
end
