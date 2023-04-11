class AddBlockedToIssues < ActiveRecord::Migration[7.0]
  def change
    add_column :issues, :blocked, :boolean
  end
end
