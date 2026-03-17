class AddMentionedUsersToReconciliations < ActiveRecord::Migration[7.2]
  def change
    add_column :reconciliations, :mentioned_users, :jsonb

  end
end
