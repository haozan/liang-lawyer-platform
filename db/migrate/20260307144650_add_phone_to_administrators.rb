class AddPhoneToAdministrators < ActiveRecord::Migration[7.2]
  def change
    # 先添加允许 null 的字段
    add_column :administrators, :phone, :string
    
    # 为现有的 admin 账户设置临时手机号
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE administrators 
          SET phone = '10000000000' 
          WHERE phone IS NULL;
        SQL
      end
    end
    
    # 添加非空约束和唯一索引
    change_column_null :administrators, :phone, false
    add_index :administrators, :phone, unique: true
  end
end
