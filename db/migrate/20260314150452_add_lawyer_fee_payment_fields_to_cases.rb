class AddLawyerFeePaymentFieldsToCases < ActiveRecord::Migration[7.2]
  def change
    add_column :cases, :lawyer_fee_received, :decimal, precision: 15, scale: 2, comment: '律师费已回款金额'
    add_column :cases, :lawyer_fee_received_at, :date, comment: '律师费回款日期'
    add_column :cases, :lawyer_fee_payment_status, :string, default: 'pending', comment: '律师费付款状态: pending(待付款), partial(部分付款), completed(已付清)'
    
    add_index :cases, :lawyer_fee_payment_status
    add_index :cases, :lawyer_fee_received_at
  end
end
