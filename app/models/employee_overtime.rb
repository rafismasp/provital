class EmployeeOvertime < ActiveRecord::Base
	belongs_to :employee

	# belongs_to :creator, :foreign_key => 'created_by', :class_name => "SysAccount"
	# belongs_to :approve1, :foreign_key => 'approve_1_by', :class_name => "SysAccount"
	# belongs_to :approve2, :foreign_key => 'approve_2_by', :class_name => "SysAccount"
	# belongs_to :approve3, :foreign_key => 'approve_3_by', :class_name => "SysAccount"
	# belongs_to :cancel1, :foreign_key => 'cancel_approve_1_by', :class_name => "SysAccount"
	# belongs_to :locked, :foreign_key => 'edit_lock_by', :class_name => "SysAccount"
end
