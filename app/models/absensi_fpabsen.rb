class AbsensiFpabsen < ApplicationRecord
  establish_connection(:absensi)
	self.table_name = "fpabsen"
end