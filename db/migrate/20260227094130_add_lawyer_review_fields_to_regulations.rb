class AddLawyerReviewFieldsToRegulations < ActiveRecord::Migration[7.2]
  def change
    add_column :regulations, :reviewed_by_lawyer, :boolean, default: false
    add_column :regulations, :last_lawyer_comment_at, :datetime

  end
end
