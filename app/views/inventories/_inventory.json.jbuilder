json.extract! inventory, :id, :periode, :begin_stock, :trans_in, :trans_out, :end_stock, :created_at, :updated_at
json.url inventory_url(inventory, format: :json)
