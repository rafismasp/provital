class TemplateBank < ApplicationRecord
	# validates :number, uniqueness: { scope: [:company_profile_id], message: "Number cannot be duplicate" }
	belongs_to :company_profile

	belongs_to :list_internal_bank_account, optional: true

	has_many :template_bank_items, -> { where status: 'active' }

	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true
	belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true
	belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true
	belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true
	belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true
	belongs_to :printed, :class_name => "User", foreign_key: "printed_by", optional: true

	before_save :update_amount
	def paid_status
		return self.status == 'paid' ? 'Paid' : 'Unpaid'
	end

	private
		def update_amount
			sum = 0
			self.template_bank_items.each do |item|
				sum += item.payment_amount
			end
			self.grand_total = sum
		end
end
