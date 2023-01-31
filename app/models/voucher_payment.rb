class VoucherPayment < ApplicationRecord
	extend OrderAsSpecified
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }

	belongs_to :company_profile
	belongs_to :currency
	belongs_to :list_internal_bank_account
	belongs_to :list_external_bank_account
	belongs_to :department, optional: true
	# belongs_to :dom_bank
  belongs_to :cash_submission, optional: true
	
	has_many :template_bank_items
	has_many :voucher_payment_items

	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true	
	belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true	
	belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true
	belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true
	belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true
	belongs_to :voided, :class_name => "User", foreign_key: "voided_by", optional: true
end