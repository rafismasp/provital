class TemplateBankItem < ApplicationRecord
	belongs_to :template_bank
	belongs_to :payment_supplier, optional: :true
	belongs_to :supplier_bank, optional: :true
	belongs_to :voucher_payment, optional: :true
	belongs_to :voucher_payment_item, optional: :true

	after_save :update_payment_status

	def payment_amount
		result = 0
		result += self.payment_supplier.grandtotal if self.payment_supplier.present?
		result += self.voucher_payment.grand_total if self.voucher_payment.present?
		return result
	end


	private
		def update_payment_status
			if self.status == 'active'
				set_status = 'Y'
			else
				set_status = 'N'
			end
			# self.payment_supplier.update_columns({
			# 	:template_bank_status=> set_status
			# })
			if payment_supplier.present?
				self.payment_supplier.update_columns({
					:template_bank_status=> set_status
				})
			end

			if voucher_payment.present?
				self.voucher_payment.update_columns({
					:template_bank_status=> set_status
				})
			end
			# else
			# 	self.fin_voucher_payment.update_columns({
			# 		:template_bank_status=> set_status
			# 	})
			# end
		end
end
