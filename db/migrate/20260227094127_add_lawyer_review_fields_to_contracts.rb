class AddLawyerReviewFieldsToContracts < ActiveRecord::Migration[7.2]
  def change
    add_column :contracts, :reviewed_by_lawyer, :boolean, default: false
    add_column :contracts, :last_lawyer_comment_at, :datetime

  end
end
