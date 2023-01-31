json.extract! purchase_request, :id, :number, :created_at, :updated_at
json.url purchase_request_url(purchase_request, format: :json)
