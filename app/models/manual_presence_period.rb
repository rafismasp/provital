class ManualPresencePeriod < ApplicationRecord
	def creator
		User.find(self.created_by).name
	end
	def void
		User.find(deleted_by).name
	end
	def unvoid
		User.find(cancel_deleted_by).name
	end
	def app1
		User.find(approved1_by).name
	end
	def app2
		User.find(approved2_by).name
	end
	def app3
		User.find(approved3_by).name
	end
	def capp1
		User.find(canceled1_by).name
	end
	def capp2
		User.find(canceled2_by).name
	end
	def capp3
		User.find(canceled3_by).name
	end
	def update_by
		User.find(updated_by).name
	end
	def edit_lock
		User.find(edit_lock_by).name
	end
end