class AddPartyRolesToCases < ActiveRecord::Migration[7.2]
  def change
    add_column :cases, :our_party_role, :string
    add_column :cases, :counterparty_role, :string

  end
end
