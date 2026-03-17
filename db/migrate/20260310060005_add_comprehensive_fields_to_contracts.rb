class AddComprehensiveFieldsToContracts < ActiveRecord::Migration[7.2]
  def change
    # ==================== 合同双方主体信息 ====================
    # 我方信息
    add_column :contracts, :our_party_role, :string
    add_column :contracts, :our_signatory, :string
    add_column :contracts, :our_signatory_title, :string
    
    # 对方信息
    add_column :contracts, :counterparty_name, :string
    add_column :contracts, :counterparty_role, :string
    add_column :contracts, :counterparty_type, :string
    add_column :contracts, :counterparty_unified_code, :string
    add_column :contracts, :counterparty_legal_rep, :string
    add_column :contracts, :counterparty_address, :string
    add_column :contracts, :counterparty_contact, :string
    add_column :contracts, :counterparty_phone, :string
    
    # ==================== 合同基本信息 ====================
    add_column :contracts, :contract_number, :string
    add_column :contracts, :contract_title, :string
    add_column :contracts, :contract_type, :string
    add_column :contracts, :signing_location, :string
    
    # ==================== 金额与支付条款 ====================
    add_column :contracts, :contract_amount, :decimal, precision: 15, scale: 2
    add_column :contracts, :currency, :string, default: '人民币'
    add_column :contracts, :amount_in_words, :string
    add_column :contracts, :payment_method, :string
    add_column :contracts, :payment_terms, :text
    
    # ==================== 履行期限与交付 ====================
    add_column :contracts, :performance_start_date, :date
    add_column :contracts, :performance_end_date, :date
    add_column :contracts, :delivery_date, :date
    add_column :contracts, :delivery_location, :string
    add_column :contracts, :acceptance_date, :date
    add_column :contracts, :warranty_period, :string
    add_column :contracts, :warranty_end_date, :date
    
    # ==================== 违约责任与救济 ====================
    add_column :contracts, :penalty_clause, :text
    add_column :contracts, :liquidated_damages, :decimal, precision: 15, scale: 2
    add_column :contracts, :dispute_resolution, :string
    add_column :contracts, :arbitration_institution, :string
    add_column :contracts, :jurisdiction_court, :string
    add_column :contracts, :applicable_law, :string
    
    # ==================== 律师审查记录 ====================
    add_column :contracts, :legal_review_status, :string, default: '待审查'
    add_column :contracts, :legal_risk_level, :string
    add_column :contracts, :legal_risk_summary, :text
    add_column :contracts, :lawyer_suggestions, :text
    add_column :contracts, :reviewed_by_lawyer_name, :string
    add_column :contracts, :reviewed_at_lawyer, :datetime
    
    # ==================== 履行状态与进度 ====================
    add_column :contracts, :performance_status, :string, default: '未开始履行'
    add_column :contracts, :performance_progress, :integer, default: 0
    add_column :contracts, :performance_notes, :text
    add_column :contracts, :last_contact_date, :date
    add_column :contracts, :next_follow_up_date, :date
    
    # ==================== 变更与补充 ====================
    add_column :contracts, :has_supplement, :boolean, default: false
    add_column :contracts, :supplement_count, :integer, default: 0
    add_column :contracts, :last_supplement_date, :date
    add_column :contracts, :has_modification, :boolean, default: false
    add_column :contracts, :modification_summary, :text
    
    # ==================== 争议与诉讼 ====================
    add_column :contracts, :dispute_status, :string, default: '无争议'
    add_column :contracts, :dispute_occurred_at, :date
    add_column :contracts, :related_case_id, :integer
    add_column :contracts, :litigation_amount, :decimal, precision: 15, scale: 2
    add_column :contracts, :litigation_notes, :text
    add_column :contracts, :case_closed_at, :date
    
    # ==================== 到期续约管理 ====================
    add_column :contracts, :auto_renewal, :boolean, default: false
    add_column :contracts, :renewal_notice_period, :integer
    add_column :contracts, :renewal_times, :integer, default: 0
    add_column :contracts, :last_renewal_date, :date
    add_column :contracts, :renewal_intention, :string
    add_column :contracts, :renewal_notes, :text
    
    # ==================== 内部管理 ====================
    add_column :contracts, :client_contact, :string
    add_column :contracts, :client_contact_phone, :string
    add_column :contracts, :client_dept, :string
    add_column :contracts, :assigned_lawyer_id, :integer
    add_column :contracts, :assistant_lawyer_ids, :integer, array: true, default: []
    add_column :contracts, :internal_notes, :text
    
    # 索引
    add_index :contracts, :contract_number
    add_index :contracts, :counterparty_name
    add_index :contracts, :contract_type
    add_index :contracts, :legal_risk_level
    add_index :contracts, :performance_status
    add_index :contracts, :dispute_status
    add_index :contracts, :assigned_lawyer_id
    add_index :contracts, :related_case_id
  end
end
