class SalesOrderFile < ApplicationRecord
  # mount_uploader :attachment, ImageUploader
  belongs_to :sales_order
end
