json.extract! voucher_payment, :id, :number, :created_at, :updated_at
json.url voucher_payment_url(voucher_payment, format: :json)
