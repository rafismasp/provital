class CdnSysFile < CdnDbBase
  self.table_name = "provital_sys_files"
  
  belongs_to :creator, :class_name => "User", foreign_key: "created_by"
  belongs_to :updator, :class_name => "User", foreign_key: "updated_by"
end