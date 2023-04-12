class AddWatcherToIssues < ActiveRecord::Migration[7.0]
  def change
    add_column :issues, :watcher, :string
  end
end
