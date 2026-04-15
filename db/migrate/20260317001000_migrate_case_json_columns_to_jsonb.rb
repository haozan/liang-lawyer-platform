# frozen_string_literal: true

# 将 cases 表中使用 coder: JSON 序列化的 text 字段迁移到 PostgreSQL 原生 jsonb 类型。
#
# 迁移字段：property_preservation_history, third_parties, claims, judgement_result, execution_measures
# 策略：PostgreSQL USING 表达式直接在 ALTER COLUMN 时转换类型（单条 DDL，无需逐行迁移）
#
class MigrateCaseJsonColumnsToJsonb < ActiveRecord::Migration[7.2]
  JSON_COLUMNS = %w[
    property_preservation_history
    third_parties
    claims
    judgement_result
    execution_measures
  ].freeze

  def up
    JSON_COLUMNS.each do |col|
      # 将 text 列直接转换为 jsonb，NULL 保持 NULL，空字符串转为 NULL
      execute <<~SQL
        ALTER TABLE cases
          ALTER COLUMN #{col} TYPE jsonb
          USING CASE
            WHEN #{col} IS NULL OR trim(#{col}) = '' THEN NULL
            ELSE #{col}::jsonb
          END
      SQL
    end
  end

  def down
    JSON_COLUMNS.each do |col|
      # 将 jsonb 转回 text（序列化为 JSON 字符串）
      execute <<~SQL
        ALTER TABLE cases
          ALTER COLUMN #{col} TYPE text
          USING #{col}::text
      SQL
    end
  end
end
