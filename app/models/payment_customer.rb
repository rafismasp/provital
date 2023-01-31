class PaymentCustomer < ApplicationRecord
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }
	
	belongs_to :company_profile
	belongs_to :customer
	belongs_to :currency
	belongs_to :bank_transfer

  before_save :update_amount

  private
  	def my_total_tax
  		case self.invoice_kind
  		when 'proforma'
	  		ProformaInvoiceCustomer.where(:company_profile_id=> self.company_profile_id, :status=> 'approved3', :payment_customer_id=>self.id).sum(:ppn_total)
  		else
	  		InvoiceCustomer.where(:company_profile_id=> self.company_profile_id, :status=> 'approved3', :payment_customer_id=>self.id).sum(:ppntotal)
	  	end
	  end
  	def my_total_amount
  		case self.invoice_kind
  		when 'proforma'
	  		ProformaInvoiceCustomer.where(:company_profile_id=> self.company_profile_id, :status=> 'approved3', :payment_customer_id=>self.id).sum(:grand_total)
  		else
	  		InvoiceCustomer.where(:company_profile_id=> self.company_profile_id, :status=> 'approved3', :payment_customer_id=>self.id).sum(:grandtotal)
	  	end
	  end

	  def update_amount
	    self.total_tax = my_total_tax
	    self.total_amount = my_total_amount
		  self.paid = (my_total_amount.to_f - self.other_cut_cost.to_f) - self.adm_fee.to_f
		end
end
