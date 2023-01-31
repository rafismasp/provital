json.extract! meeting_minute, :id, :subject, :venue, :note, :created_at, :updated_at
json.url meeting_minute_url(meeting_minute, format: :json)
