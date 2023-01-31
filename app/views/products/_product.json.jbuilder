json.extract! product, :id, :name, :part_id, :unit_id, :color_id, :created_at, :updated_at
json.url product_url(product, format: :json)
