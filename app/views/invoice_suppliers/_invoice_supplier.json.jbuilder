json.extract! invoice_supplier, :id, :number, :created_at, :updated_at
json.url invoice_supplier_url(invoice_supplier, format: :json)
