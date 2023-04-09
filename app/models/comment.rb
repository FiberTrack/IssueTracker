class Comment < ApplicationRecord
  belongs_to :issue
  belongs_to :user

  def author_name
    user.full_name
  end

  def author_avatar
    user.avatar_url
  end
end
