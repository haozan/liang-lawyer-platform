class AddLawyerFeeDetailsToCase < ActiveRecord::Migration[7.2]
  def change
    add_column :cases, :lawyer_fee_payment_terms, :text

  end
end
