class InvoiceCustomer < ApplicationRecord
	validates :number, uniqueness: { scope: :company_profile_id, message: "cannot be duplicate" }
	has_many :invoice_customer_items

	belongs_to :company_profile
	belongs_to :customer_tax_invoice, optional: true
	belongs_to :payment_customer, optional: true
	belongs_to :tax, optional: true
	belongs_to :customer
	belongs_to :currency
	belongs_to :term_of_payment
	belongs_to :company_payment_receiving, optional: true
	
	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true
	belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true
	belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true
	belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true
	belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true

	scope :tax_unused, -> { where("customer_tax_invoice_id is null and status = 'approved3' ") }

  before_save :update_amount

  private
	  def sum_subtotal
	   	self.invoice_customer_items.where(:status=> 'active').to_a.sum { |item| item.total_price }
	  end
	  def sum_ppn
	   	# invoice_customer_items.where(:status=> 'active').to_a.sum { |item| (item.sales_order_item.sales_order.tax.name == "PPN 10%" ? item.total_price.to_f * 0.10 : 0) }

	   	# 2021-12-20 aden: tax value di set pada Header Invoice, kasus customer Maesindo yg bisa ganti ganti Jenis Pajak pada SO
	   	tax_value = self.tax.value

      # 2022-04-02: preventif untuk Invoice bulan maret di update bulan april
      if self.date.to_date.strftime("%Y-%m-%d") < '2022-04-01'
        if tax_value == 0.11
          tax_value = 0.10
        end
      else
      	# 2022-04-07: tax_value invoice berdasarkan tax PO customer 
        if tax_value == 0.10
          tax_value = 0.11
        end
      end

	   	tax_value.to_f > 0 ? self.invoice_customer_items.where(:status=> 'active').to_a.sum { |item| item.total_price.to_f * tax_value.to_f } : 0
	  end

	  def update_amount
	    grand_total = (sum_subtotal.to_f-self.discount.to_f)+sum_ppn.to_f
	    self.subtotal = sum_subtotal
		  self.ppntotal = sum_ppn
		  self.grandtotal = grand_total
		end
end
