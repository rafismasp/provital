module CustomersHelper
	def customer_code
		customers = Customer.where(:company_profile_id=> current_user.company_profile_id, :status=> 'active').order("number asc")
		if customers.present?
			last_number = customers.last.number
			prefix = "CP"
			last_number.slice! prefix
			suffix = last_number
			
			seq = suffix.to_i+1
			length_seq = seq.to_s.length
			case length_seq.to_i
			when 1
				prefix_seq = '00'
			when 2
				prefix_seq = '0'
			else
				prefix_seq = ''
			end

			result = "#{prefix}#{prefix_seq}#{seq}"
			return result
		end
	end
end
