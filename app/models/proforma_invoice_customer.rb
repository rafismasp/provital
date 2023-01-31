class ProformaInvoiceCustomer < ApplicationRecord
	extend OrderAsSpecified
	validates :number, uniqueness: { scope: [:company_profile_id], message: "has already been taken" }

	belongs_to :company_profile
	belongs_to :payment_customer, optional: true
	belongs_to :customer, optional: true
	belongs_to :tax, optional: true
	belongs_to :term_of_payment, optional: true
	belongs_to :sales_order, optional: true
	belongs_to :sales_order_item, optional: true
	has_many :proforma_invoice_customer_items

	belongs_to :created, :class_name => "User", foreign_key: "created_by", optional: true
	belongs_to :updated, :class_name => "User", foreign_key: "updated_by", optional: true
	belongs_to :approved1, :class_name => "User", foreign_key: "approved1_by", optional: true	
	belongs_to :approved2, :class_name => "User", foreign_key: "approved2_by", optional: true	
	belongs_to :approved3, :class_name => "User", foreign_key: "approved3_by", optional: true
	belongs_to :canceled1, :class_name => "User", foreign_key: "canceled1_by", optional: true
	belongs_to :canceled2, :class_name => "User", foreign_key: "canceled2_by", optional: true
	belongs_to :canceled3, :class_name => "User", foreign_key: "canceled3_by", optional: true
	belongs_to :voided, :class_name => "User", foreign_key: "voided_by", optional: true

	after_save :set_amount
	private
		def set_amount
			ppn_total = self.tax.value.to_f

      total = 0
      discount = 0
      dp_percent = self.down_payment.to_f
      self.proforma_invoice_customer_items.each do |item|
        if item.status == 'active'
          amount = item.sales_order_item.unit_price.to_f * item.sales_order_item.quantity.to_f
          total += amount
          discount += item.amountdisc
          puts "[#{item.id}] amount: #{item.amount} => #{amount} [#{amount == item.amount}]"
          item.update_columns({:amount=> amount})
        end

      end
      total_dp = total.to_f * (dp_percent /100)
      amount   = 0

      if dp_percent.to_i == 0
        discount_total = discount
        amount = grand_total
      else
        discount_total = discount * (dp_percent / 100)
        amount = total_dp
      end
      
      # PPN
      total_ppn = (amount - discount_total) * ppn_total ;
      # Grand Total
      total_gt = (amount - discount_total + total_ppn);

      puts "#{self.id} #{self.number}"
      puts "=== total   : #{self.total} => #{total} [#{total == self.total}]"
      puts "=== total DP: #{self.down_payment_total} => #{total_dp} [#{total_dp == self.down_payment_total}]"
      puts "=== Ttl.DIsc: #{self.discount_total} => #{discount_total} [#{discount_total == self.discount_total}]"
      puts "=== TotalPPN: #{self.ppn_total} => #{total_ppn} [#{total_ppn == self.ppn_total}]"
      puts "=== GrandTtl: #{self.grand_total} => #{total_gt} [#{total_gt == self.grand_total}]"
      self.update_columns({
        :total => total,
        :down_payment_total=> total_dp,
        :discount_total=> discount_total,
        :ppn_total=> total_ppn,
        :grand_total=> total_gt
      })
		end
end