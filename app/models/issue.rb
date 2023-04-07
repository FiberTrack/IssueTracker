class Issue < ApplicationRecord

    after_initialize :set_defaults

  def set_defaults
    self.assign ||= "Not Assigned"
    self.issue_type ||= "Bug"
    self.severity ||= "Wishlist"
    self.priority ||= "Low"
  end
end
