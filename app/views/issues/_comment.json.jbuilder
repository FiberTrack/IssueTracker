json.extract! comment, :id, :content, :issue_id, :created_at, :updated_at, :user_id
json.url issue_comment_url(comment.issue, comment, format: :json)