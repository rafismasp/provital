class PurchaseRequest < ApplicationRecord
	extend OrderAsSpecified
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }
	has_many :purchase_request_items
	has_many :virtual_receivings

	belongs_to :company_profile
	belongs_to :department
	belongs_to :employee_section, optional: true

	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true	
	belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true	
	belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true
	belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true
	belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true
	belongs_to :voided, :class_name => "User", foreign_key: "voided_by", optional: true

  before_save :update_outstanding

	def basic_request
		result = 'Manual'
		case self.automatic_calculation
		when 1
			result = 'From SPP'
		else
			self.purchase_request_items.each do |item|
				if item.production_order_used_prves.present?
					result = 'Manual by SPP'
				end
			end
			if self.virtual_receivings.present?
				result = 'From Virtual Receiving'
			end
		end
		return result
	end

  private

	  def update_outstanding
	  	sum_outstanding  = self.purchase_request_items.where(:status=> 'active').where("outstanding > 0").sum(:outstanding)
	    self.outstanding = sum_outstanding
		end
end
