class MeetingMinuteItem < ApplicationRecord
	belongs_to :meeting_minute
	belongs_to :account_pic1, :class_name => "User", foreign_key: "pic1", optional: true
	belongs_to :account_pic2, :class_name => "User", foreign_key: "pic2", optional: true
	belongs_to :account_pic3, :class_name => "User", foreign_key: "pic3", optional: true
	belongs_to :account_pic4, :class_name => "User", foreign_key: "pic4", optional: true
	belongs_to :account_pic5, :class_name => "User", foreign_key: "pic5", optional: true


	def job_status(i)
		joblist = JobListReport.find_by(:meeting_minute_item_id=> self.id, :user_id=> self["pic#{i}"], :checked=>1)
		if joblist.present?
			case joblist.status 
			when "active"
				return "done"
			else
				return "#{joblist.status}"
			end
		end
	end

	def job_note(i)
		joblist = JobListReport.find_by(:meeting_minute_item_id=> self.id, :user_id=> self["pic#{i}"], :checked=>1)
		if joblist.present?
			return joblist.note
		end
	end
end
