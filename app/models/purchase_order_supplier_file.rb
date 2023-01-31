class PurchaseOrderSupplierFile < ApplicationRecord
  # mount_uploader :attachment, ImageUploader
  belongs_to :purchase_order_supplier
end
