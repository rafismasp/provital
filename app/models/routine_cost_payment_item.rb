class RoutineCostPaymentItem < ApplicationRecord
  belongs_to :routine_cost
  belongs_to :routine_cost_interval
  belongs_to :routine_cost_payment
end
