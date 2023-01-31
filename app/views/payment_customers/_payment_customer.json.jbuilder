json.extract! payment_customer, :id, :number, :created_at, :updated_at
json.url payment_customer_url(payment_customer, format: :json)
