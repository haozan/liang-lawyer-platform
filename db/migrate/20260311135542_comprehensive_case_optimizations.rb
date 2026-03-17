class ComprehensiveCaseOptimizations < ActiveRecord::Migration[7.2]
  def change
    # 1. 多委托人管理 - 创建 case_clients 中间表
    create_table :case_clients do |t|
      t.references :case, null: false, foreign_key: true, index: true
      t.references :company, null: false, foreign_key: true, index: true
      t.string :role, default: 'client'  # 角色: primary_client(主委托人), co_client(共同委托人), third_party(第三人)
      t.integer :position, default: 0    # 排序
      t.date :joined_at                  # 加入日期
      t.text :notes                      # 备注
      
      t.timestamps
    end
    
    # 确保同一案件同一公司只有一条记录
    add_index :case_clients, [:case_id, :company_id], unique: true
    add_index :case_clients, :role
    add_index :case_clients, :position
    
    # 2. 案件表添加标的额相关字段
    add_column :cases, :claim_amount, :decimal, precision: 15, scale: 2, comment: '诉讼标的额'
    add_column :cases, :awarded_amount, :decimal, precision: 15, scale: 2, comment: '判决/调解金额'
    add_column :cases, :litigation_fee, :decimal, precision: 15, scale: 2, comment: '诉讼费'
    add_column :cases, :lawyer_fee, :decimal, precision: 15, scale: 2, comment: '律师费'
    add_column :cases, :amount_status, :string, comment: '金额状态: pending(待判决), awarded(已判决), paid(已支付), partial_paid(部分支付)'
    
    # 3. 案件表添加当事人信息字段
    add_column :cases, :our_party_name, :string, comment: '我方当事人名称'
    add_column :cases, :counterparty_name, :string, comment: '对方当事人名称'
    add_column :cases, :counterparty_lawyer, :string, comment: '对方代理律师'
    add_column :cases, :counterparty_lawfirm, :string, comment: '对方律师事务所'
    add_column :cases, :counterparty_contact, :string, comment: '对方联系方式'
    add_column :cases, :third_parties, :text, comment: '第三人信息（JSON格式）'
    
    # 4. 案件表添加诉讼请求和判决结果字段
    add_column :cases, :claims, :text, comment: '诉讼请求（JSON数组）'
    add_column :cases, :judgement_result, :text, comment: '判决结果（JSON数组）'
    add_column :cases, :case_outcome, :string, comment: '案件结局: total_win(全胜), partial_win(部分胜诉), lose(败诉), settled(调解), withdrawn(撤诉)'
    
    # 5. 案件表添加执行阶段细化字段
    add_column :cases, :execution_start_at, :date, comment: '执行立案日期'
    add_column :cases, :execution_deadline, :date, comment: '执行期限'
    add_column :cases, :execution_measures, :text, comment: '执行措施（JSON数组）'
    add_column :cases, :executed_amount, :decimal, precision: 15, scale: 2, comment: '已执行金额'
    add_column :cases, :execution_status, :string, comment: '执行状态: executing(执行中), terminated(终本), settled(和解执行), completed(执行完毕)'
    add_column :cases, :execution_notes, :text, comment: '执行备注'
    
    # 添加索引以提高查询性能
    add_index :cases, :claim_amount
    add_index :cases, :amount_status
    add_index :cases, :case_outcome
    add_index :cases, :execution_start_at
    add_index :cases, :execution_status
    add_index :cases, :counterparty_name
    add_index :cases, :our_party_name
  end
end
