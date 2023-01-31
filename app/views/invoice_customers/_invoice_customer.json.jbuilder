json.extract! invoice_customer, :id, :number, :created_at, :updated_at
json.url invoice_customer_url(invoice_customer, format: :json)
