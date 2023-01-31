class CashSubmissionFile < ApplicationRecord
  # mount_uploader :attachment, ImageUploader
  belongs_to :cash_submission
end
