class AddNewColumnsToIssues < ActiveRecord::Migration[7.0]
  def change
    add_column :issues, :type, :string
    add_column :issues, :severity, :string
    add_column :issues, :priority, :string
  end
end
