class CreateActivities < ActiveRecord::Migration[7.0]
  def change
    create_table :activities do |t|
      t.integer :user_id
      t.integer :issue_id
      t.string :action

      t.timestamps
    end
  end
end
