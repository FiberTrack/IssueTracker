class CreateIssueWatchers < ActiveRecord::Migration[7.0]
  def change
    create_table :issue_watchers do |t|
      t.references :issue, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true


    end
  end
end
