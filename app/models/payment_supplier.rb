class PaymentSupplier < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }
	has_many :payment_supplier_items
	has_many :payment_request_suppliers
	has_many :template_bank_items
	
	belongs_to :company_profile
	belongs_to :supplier
	belongs_to :currency
	belongs_to :supplier_payment_method
	belongs_to :bank_transfer
	
	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true	
	belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true	
	belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true	
	belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true	
	belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true	

  # after_create :update_total, :update_payment_request
  # after_update :update_total, :update_payment_request
  
  before_save :update_payment_request, :update_total

  private
	  def update_total
      self.subtotal = payment_request_suppliers.where(:status=> 'approved3').sum(:subtotal)
      self.ppntotal = payment_request_suppliers.where(:status=> 'approved3').sum(:ppntotal)
      self.pphtotal = payment_request_suppliers.where(:status=> 'approved3').sum(:pphtotal)
      self.dptotal  = payment_request_suppliers.where(:status=> 'approved3').sum(:dptotal)
      self.grandtotal = payment_request_suppliers.where(:status=> 'approved3').sum(:grandtotal)
		end

		def update_payment_request
			if self.status == 'deleted'
				PaymentSupplierItem.where(:payment_supplier_id=> self.id, :status=> 'active').each do |payment_item|
		      payment_item.update({:status=> 'deleted'})
		      payment_item.payment_request_supplier.update({:payment_supplier_id=> nil})
		    end
		    logger.info "clear Payment Request"
		  else
		  	# create or update =>  payment update payment request
				PaymentSupplierItem.where(:payment_supplier_id=> self.id, :status=> 'active').each do |payment_item|
					payment_item.payment_request_supplier.update({:payment_supplier_id=> self.id})
        end
		  end
		end
end
