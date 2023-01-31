class WorkingHourSummaryItem < ApplicationRecord
	belongs_to :working_hour_summary
	belongs_to :schedule
end
