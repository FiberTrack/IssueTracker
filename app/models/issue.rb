class Issue < ApplicationRecord

    serialize :watcher_ids, Array

    after_initialize :set_defaults
    has_many :attachments
    has_many :comments, dependent: :destroy
    has_many :activities
    has_many :issue_watchers
    has_many :users, through: :issue_watchers









  def set_defaults
    self.watcher_ids ||= nil
    self.assign ||= "Not Assigned"
    self.issue_type ||= "Bug"
    self.severity ||= "Wishlist"
    self.priority ||= "Low"
  end


end
