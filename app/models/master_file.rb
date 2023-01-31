class MasterFile < ApplicationRecord
  belongs_to :company_profile
  
  belongs_to :creator, :class_name => "User", foreign_key: "created_by"
  belongs_to :updator, :class_name => "User", foreign_key: "updated_by"
end
