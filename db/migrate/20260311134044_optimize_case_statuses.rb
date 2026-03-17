class OptimizeCaseStatuses < ActiveRecord::Migration[7.2]
  def up
    # Step 1: 添加新的状态值
    # 当前状态: pending, investigating, in_court, judgement, closed
    # 新状态映射:
    # - preparing (准备立案) <- pending
    # - filed (已立案待审) <- investigating
    # - trial (审理中) <- in_court
    # - judged (已判决) <- judgement
    # - execution (执行中) <- 新增
    # - settled (调解结案) <- 新增
    # - closed (已归档) <- closed
    
    # Step 2: 迁移现有数据
    # pending -> preparing
    execute <<-SQL
      UPDATE cases 
      SET status = 'preparing' 
      WHERE status = 'pending'
    SQL
    
    # investigating -> filed
    execute <<-SQL
      UPDATE cases 
      SET status = 'filed' 
      WHERE status = 'investigating'
    SQL
    
    # in_court -> trial
    execute <<-SQL
      UPDATE cases 
      SET status = 'trial' 
      WHERE status = 'in_court'
    SQL
    
    # judgement -> judged
    execute <<-SQL
      UPDATE cases 
      SET status = 'judged' 
      WHERE status = 'judgement'
    SQL
    
    # closed保持不变
    
    # Step 3: 添加索引以提升查询性能
    add_index :cases, :status unless index_exists?(:cases, :status)
  end
  
  def down
    # 回滚数据迁移
    execute <<-SQL
      UPDATE cases 
      SET status = 'pending' 
      WHERE status = 'preparing'
    SQL
    
    execute <<-SQL
      UPDATE cases 
      SET status = 'investigating' 
      WHERE status = 'filed'
    SQL
    
    execute <<-SQL
      UPDATE cases 
      SET status = 'in_court' 
      WHERE status = 'trial'
    SQL
    
    execute <<-SQL
      UPDATE cases 
      SET status = 'judgement' 
      WHERE status = 'judged'
    SQL
    
    # 新增的状态回滚到最接近的旧状态
    execute <<-SQL
      UPDATE cases 
      SET status = 'judged' 
      WHERE status = 'execution'
    SQL
    
    execute <<-SQL
      UPDATE cases 
      SET status = 'closed' 
      WHERE status = 'settled'
    SQL
    
    remove_index :cases, :status if index_exists?(:cases, :status)
  end
end
