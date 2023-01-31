class MeetingMinuteAttendence < ApplicationRecord
	belongs_to :user
	belongs_to :meeting_minute
end
