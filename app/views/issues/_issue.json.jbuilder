json.extract! issue, :id, :subject, :description, :assign, :created_at, :updated_at, :severity, :priority, :issue_type, :blocked, :deadline, :watcher, :watcher_ids, :status, :created_by
json.url issue_url(issue, format: :json)
