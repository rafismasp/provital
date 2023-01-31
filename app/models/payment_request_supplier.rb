class PaymentRequestSupplier < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }
	
	belongs_to :company_profile
	belongs_to :supplier
	belongs_to :currency
	belongs_to :supplier_payment_method
	belongs_to :payment_supplier, optional: true
	belongs_to :bank_transfer

	has_many :payment_request_supplier_items
 	
  before_save :update_total_payreq

  private
	  def update_total_payreq
	  	new_subtotal = 0
	  	new_ppntotal = 0
	  	new_pphtotal = 0
	  	new_dptotal  = 0
	  	new_grandtotal = 0

	  	self.payment_request_supplier_items.where(:status=> 'active').each do |item|
	  		if item.invoice_supplier.present?
		  		new_subtotal += item.invoice_supplier.subtotal 
		  		new_ppntotal += item.invoice_supplier.ppntotal
		  		new_pphtotal += item.invoice_supplier.pphtotal
		  		new_dptotal += item.invoice_supplier.dptotal
		  		new_grandtotal += item.invoice_supplier.grandtotal
		  	end
	  	end

	  	self.subtotal = new_subtotal
	  	self.ppntotal = new_ppntotal
	  	self.pphtotal = new_pphtotal
	  	self.dptotal = new_dptotal
	  	self.grandtotal = new_grandtotal
	  end
end
