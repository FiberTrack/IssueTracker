class Issue < ApplicationRecord

    after_initialize :set_defaults
    has_many :attachments
    has_many :comments, dependent: :destroy
    has_many :activities


  def set_defaults
    self.assign ||= "Not Assigned"
    self.issue_type ||= "Bug"
    self.severity ||= "Wishlist"
    self.priority ||= "Low"
  end

end
