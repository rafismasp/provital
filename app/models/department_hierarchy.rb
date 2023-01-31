class DepartmentHierarchy < ApplicationRecord
	belongs_to :department

	belongs_to :approved1, :foreign_key => 'approved1_by', :class_name => "User"
	belongs_to :canceled1, :foreign_key => 'cancel1_by', :class_name => "User"
	belongs_to :approved2, :foreign_key => 'approved2_by', :class_name => "User"
	belongs_to :canceled2, :foreign_key => 'cancel2_by', :class_name => "User"
	belongs_to :approved3, :foreign_key => 'approved3_by', :class_name => "User"
	belongs_to :canceled3, :foreign_key => 'cancel3_by', :class_name => "User"
	belongs_to :voided, :foreign_key => 'void_by', :class_name => "User"

end
