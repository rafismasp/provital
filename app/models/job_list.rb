class JobList < ApplicationRecord
	belongs_to :company_profile
	belongs_to :user
	belongs_to :department
	belongs_to :job_category
end
