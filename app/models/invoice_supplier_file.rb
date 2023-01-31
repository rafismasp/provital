class InvoiceSupplierFile < ApplicationRecord
  # mount_uploader :attachment, ImageUploader
  belongs_to :invoice_supplier
end
