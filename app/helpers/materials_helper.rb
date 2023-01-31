module MaterialsHelper

	def material_code(category_id)		
		category = MaterialCategory.find_by(:id=> category_id)
		category_code = (category.present? ? category.code : "X")
		records = Material.where(:material_category_id=> category_id).order("part_id asc")
		
	  # seq 3 digit
    seq = (records.present? ? records.last.part_id.to_s[1,3].to_i+1 : 1)
    length_seq = seq.to_s.length

    if length_seq == 1 
      number = "00"+seq.to_s
    elsif length_seq == 2 
      number = "0"+seq.to_s
    else
      number = seq.to_s
    end
    seq_number = "#{category_code}#{number}"
    return seq_number
	end
end
