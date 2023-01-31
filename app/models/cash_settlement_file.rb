class CashSettlementFile < ApplicationRecord
  # mount_uploader :attachment, ImageUploader
  belongs_to :cash_settlement
end
