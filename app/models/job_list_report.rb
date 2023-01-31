class JobListReport < ApplicationRecord
	belongs_to :company_profile
	belongs_to :user
	belongs_to :department, optional: true
	belongs_to :job_category, optional: true
	belongs_to :meeting_minute_item, optional: true
end
