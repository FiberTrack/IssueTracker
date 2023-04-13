class AddWatcherIdsToIssues < ActiveRecord::Migration[7.0]
  def change
    add_column :issues, :watcher_ids, :text
  end
end
