class AddLawyerFeeInvoiceFieldsToCases < ActiveRecord::Migration[7.2]
  def change
    add_column :cases, :lawyer_fee_invoice_issued, :boolean, default: false, comment: '律师费是否已开发票'
    add_column :cases, :lawyer_fee_invoice_number, :string, comment: '律师费发票号码'
    add_column :cases, :lawyer_fee_invoice_issued_at, :date, comment: '律师费开票日期'
    add_column :cases, :lawyer_fee_invoice_amount, :decimal, precision: 15, scale: 2, comment: '律师费开票金额'
    
    add_index :cases, :lawyer_fee_invoice_issued
    add_index :cases, :lawyer_fee_invoice_number
  end
end
