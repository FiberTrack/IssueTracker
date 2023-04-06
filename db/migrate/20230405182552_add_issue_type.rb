class AddIssueType < ActiveRecord::Migration[7.0]
  def change
    add_column :issues, :issue_types, :string
  end
end
