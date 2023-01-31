class PcAbsensiLog < ApplicationRecord
	self.abstract_class = true
  establish_connection(:output_production)
	self.table_name = "hrd_absensi_logs"
end
