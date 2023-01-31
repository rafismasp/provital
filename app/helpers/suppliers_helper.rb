module SuppliersHelper
	def supplier_code(period)
    if period.present?
      year_yyyy = period.to_date.strftime("%Y")
      prefix_code = "PS"
      records = Supplier.where(:company_profile_id=> current_user.company_profile_id).where("created_at between ? and ?", period.to_date.at_beginning_of_year(), period.to_date.at_end_of_year()).order("number asc")
      # seq 3 digit
      seq = (records.present? ? records.last.number.to_s[8,3].to_i+1 : 1)
      length_seq = seq.to_s.length

      if length_seq == 1 
        number = "00"+seq.to_s
      elsif length_seq == 2 
        number = "0"+seq.to_s
      else
        number = seq.to_s
      end
      seq_number = prefix_code+"-"+year_yyyy+"-"+number
    else
      seq_number = nil
    end
    return seq_number
	end
end
