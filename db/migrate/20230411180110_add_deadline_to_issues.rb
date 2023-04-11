class AddDeadlineToIssues < ActiveRecord::Migration[7.0]
  def change
    add_column :issues, :deadline, :date
  end
end
