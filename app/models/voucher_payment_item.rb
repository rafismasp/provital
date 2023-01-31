class VoucherPaymentItem < ApplicationRecord
  belongs_to :voucher_payment
  belongs_to :routine_cost_payment, optional: true
  belongs_to :routine_cost_payment_item, optional: true
  belongs_to :proof_cash_expenditure, optional: true
  belongs_to :proof_cash_expenditure_item, optional: true
  belongs_to :cash_settlement, optional: true
  belongs_to :cash_settlement_item, optional:true
end