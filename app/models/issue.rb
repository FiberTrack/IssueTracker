class Issue < ApplicationRecord

    after_initialize :set_defaults
    has_many :comments, dependent: :destroy
    has_and_belongs_to_many :users
    attr_accessor :user_ids





  def set_defaults
    self.assign ||= "Not Assigned"
    self.issue_type ||= "Bug"
    self.severity ||= "Wishlist"
    self.priority ||= "Low"
  end


  def selected_users
  User.where(id: self.user_ids)
  end


end
