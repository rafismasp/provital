class JobListLog < ApplicationRecord
	belongs_to :company_profile
	belongs_to :job_list
end
