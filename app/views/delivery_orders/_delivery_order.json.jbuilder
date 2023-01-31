json.extract! delivery_order, :id, :number, :created_at, :updated_at
json.url delivery_order_url(delivery_order, format: :json)
