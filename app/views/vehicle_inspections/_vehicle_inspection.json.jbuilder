json.extract! vehicle_inspection, :id, :delivery_order_id, :date, :vehicle_type, :vehicle_no, :created_at, :updated_at
json.url vehicle_inspection_url(vehicle_inspection, format: :json)
