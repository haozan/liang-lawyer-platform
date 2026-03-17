module MajorIssueStateMachine
  extend ActiveSupport::Concern
  
  included do
    include AASM
    
    aasm column: :status do
      state :pending, initial: true
      state :discussing
      state :resolved
      state :archived
      
      # 待讨论 -> 讨论中（有律师或公司用户评论时自动触发）
      event :start_discussing do
        transitions from: :pending, to: :discussing
        
        after do
          update_column(:discussing_at, Time.current)
        end
      end
      
      # 讨论中 -> 已解决（手动标记）
      event :resolve do
        transitions from: [:pending, :discussing], to: :resolved
        
        after do
          update_column(:resolved_at, Time.current)
        end
      end
      
      # 已解决 -> 已归档（手动归档）
      event :archive do
        transitions from: :resolved, to: :archived
        
        after do
          update_column(:archived_at, Time.current)
        end
      end
      
      # 重新打开
      event :reopen do
        transitions from: [:resolved, :archived], to: :discussing
        
        after do
          update_columns(resolved_at: nil, archived_at: nil)
        end
      end
    end
  end
end
