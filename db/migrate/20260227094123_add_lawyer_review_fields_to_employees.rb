class AddLawyerReviewFieldsToEmployees < ActiveRecord::Migration[7.2]
  def change
    add_column :employees, :reviewed_by_lawyer, :boolean, default: false
    add_column :employees, :last_lawyer_comment_at, :datetime

  end
end
